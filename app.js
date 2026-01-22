// Health Insights App - Main Application Logic

class HealthApp {
    constructor() {
        this.db = null;
        this.healthData = {
            steps: [],
            heartRate: [],
            sleep: [],
            activeEnergy: [],
            weight: [],
            workouts: []
        };
        this.chart = null;
        this.init();
    }

    async init() {
        await this.initDB();
        await this.loadData();
        this.setupEventListeners();
        this.updateUI();
        this.checkDailyInsights();
    }

    // IndexedDB Setup
    async initDB() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open('HealthInsightsDB', 1);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve();
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;

                if (!db.objectStoreNames.contains('healthData')) {
                    db.createObjectStore('healthData', { keyPath: 'type' });
                }
                if (!db.objectStoreNames.contains('settings')) {
                    db.createObjectStore('settings', { keyPath: 'key' });
                }
                if (!db.objectStoreNames.contains('insights')) {
                    const insightStore = db.createObjectStore('insights', { keyPath: 'id', autoIncrement: true });
                    insightStore.createIndex('date', 'date', { unique: false });
                }
            };
        });
    }

    async saveData(storeName, data) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readwrite');
            const store = transaction.objectStore(storeName);
            const request = store.put(data);

            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }

    async getData(storeName, key) {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([storeName], 'readonly');
            const store = transaction.objectStore(storeName);
            const request = store.get(key);

            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    async loadData() {
        try {
            const types = ['steps', 'heartRate', 'sleep', 'activeEnergy', 'weight', 'workouts'];
            for (const type of types) {
                const data = await this.getData('healthData', type);
                if (data) {
                    this.healthData[type] = data.records || [];
                }
            }
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }

    // Event Listeners
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchView(e.target.dataset.view));
        });

        // Modals
        document.getElementById('menuBtn').addEventListener('click', () => this.openModal('settingsModal'));
        document.getElementById('importBtn').addEventListener('click', () => this.openModal('importModal'));
        document.getElementById('closeSettings').addEventListener('click', () => this.closeModal('settingsModal'));
        document.getElementById('closeImport').addEventListener('click', () => this.closeModal('importModal'));

        // Import
        document.getElementById('processFileBtn').addEventListener('click', () => this.processHealthFile());

        // Insights
        document.getElementById('generateInsightsBtn').addEventListener('click', () => this.generateInsights());

        // Chart controls
        document.getElementById('metricSelect').addEventListener('change', () => this.updateChart());
        document.getElementById('periodSelect').addEventListener('change', () => this.updateChart());

        // Settings
        document.getElementById('exportDataBtn').addEventListener('click', () => this.exportData());
        document.getElementById('clearDataBtn').addEventListener('click', () => this.clearAllData());

        // Close modals on background click
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeModal(modal.id);
                }
            });
        });
    }

    // UI Updates
    updateUI() {
        // Update date
        const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        document.getElementById('currentDate').textContent = new Date().toLocaleDateString('en-US', options);

        // Update stats
        this.updateDashboardStats();
        this.updateDailySummary();
    }

    updateDashboardStats() {
        const today = new Date().toISOString().split('T')[0];

        // Steps
        const todaySteps = this.healthData.steps
            .filter(r => r.date === today)
            .reduce((sum, r) => sum + r.value, 0);
        document.getElementById('stepsToday').textContent = todaySteps > 0 ? todaySteps.toLocaleString() : '--';

        // Heart Rate (average for today)
        const todayHR = this.healthData.heartRate.filter(r => r.date === today);
        if (todayHR.length > 0) {
            const avgHR = Math.round(todayHR.reduce((sum, r) => sum + r.value, 0) / todayHR.length);
            document.getElementById('heartRate').textContent = `${avgHR} bpm`;
        } else {
            document.getElementById('heartRate').textContent = '--';
        }

        // Sleep (last night)
        const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
        const sleepData = this.healthData.sleep.filter(r => r.date === yesterday || r.date === today);
        if (sleepData.length > 0) {
            const totalSleep = sleepData.reduce((sum, r) => sum + r.value, 0);
            const hours = Math.floor(totalSleep);
            const minutes = Math.round((totalSleep - hours) * 60);
            document.getElementById('sleep').textContent = `${hours}h ${minutes}m`;
        } else {
            document.getElementById('sleep').textContent = '--';
        }

        // Active Calories
        const todayCalories = this.healthData.activeEnergy
            .filter(r => r.date === today)
            .reduce((sum, r) => sum + r.value, 0);
        document.getElementById('calories').textContent = todayCalories > 0 ? Math.round(todayCalories).toLocaleString() : '--';
    }

    updateDailySummary() {
        const summary = document.getElementById('dailySummary');

        if (this.healthData.steps.length === 0) {
            summary.innerHTML = '<p class="placeholder">Import your Apple Health data to see your daily summary.</p>';
            return;
        }

        const today = new Date().toISOString().split('T')[0];
        const steps = this.healthData.steps.filter(r => r.date === today).reduce((sum, r) => sum + r.value, 0);
        const calories = this.healthData.activeEnergy.filter(r => r.date === today).reduce((sum, r) => sum + r.value, 0);

        let summaryText = '<p>';

        if (steps >= 10000) {
            summaryText += '🎉 Great job! You\'ve hit your 10,000 step goal today. ';
        } else if (steps > 5000) {
            summaryText += `💪 You're making progress with ${steps.toLocaleString()} steps so far. `;
        } else if (steps > 0) {
            summaryText += `🚶 You've taken ${steps.toLocaleString()} steps today. Keep moving! `;
        }

        if (calories > 500) {
            summaryText += `🔥 You've burned ${Math.round(calories)} active calories. `;
        }

        summaryText += '</p>';
        summary.innerHTML = summaryText || '<p>Start your day with some activity!</p>';
    }

    // View Management
    switchView(viewName) {
        document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));

        document.getElementById(viewName).classList.add('active');
        document.querySelector(`[data-view="${viewName}"]`).classList.add('active');

        if (viewName === 'trends') {
            setTimeout(() => this.updateChart(), 100);
        }
    }

    openModal(modalId) {
        document.getElementById(modalId).classList.add('active');
    }

    closeModal(modalId) {
        document.getElementById(modalId).classList.remove('active');
    }

    // Data Import
    async processHealthFile() {
        const fileInput = document.getElementById('fileInput');
        const file = fileInput.files[0];

        if (!file) {
            alert('Please select a file');
            return;
        }

        document.getElementById('loadingOverlay').classList.add('active');
        document.getElementById('importProgress').textContent = 'Reading file...';

        try {
            let xmlText;

            if (file.name.endsWith('.zip')) {
                // Handle ZIP file
                const JSZip = window.JSZip || await this.loadJSZip();
                const zip = await JSZip.loadAsync(file);
                const exportFile = zip.file('apple_health_export/export.xml');
                if (!exportFile) {
                    throw new Error('export.xml not found in ZIP file');
                }
                xmlText = await exportFile.async('text');
            } else {
                // Handle XML file directly
                xmlText = await file.text();
            }

            document.getElementById('importProgress').textContent = 'Parsing health data...';
            await this.parseHealthData(xmlText);

            document.getElementById('importProgress').innerHTML = '✅ Import complete! Processing ' +
                Object.values(this.healthData).reduce((sum, arr) => sum + arr.length, 0) + ' records.';

            await this.loadData();
            this.updateUI();

            setTimeout(() => {
                document.getElementById('loadingOverlay').classList.remove('active');
                this.closeModal('importModal');
            }, 1500);

        } catch (error) {
            console.error('Error processing file:', error);
            document.getElementById('importProgress').innerHTML = '❌ Error: ' + error.message;
            document.getElementById('loadingOverlay').classList.remove('active');
        }
    }

    async parseHealthData(xmlText) {
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, 'text/xml');

        const records = xmlDoc.getElementsByTagName('Record');

        const dataMap = {
            steps: [],
            heartRate: [],
            sleep: [],
            activeEnergy: [],
            weight: []
        };

        for (let i = 0; i < records.length; i++) {
            const record = records[i];
            const type = record.getAttribute('type');
            const value = parseFloat(record.getAttribute('value'));
            const startDate = record.getAttribute('startDate');
            const endDate = record.getAttribute('endDate');

            if (!startDate || isNaN(value)) continue;

            const date = startDate.split(' ')[0];
            const recordData = { date, value, startDate, endDate };

            if (type === 'HKQuantityTypeIdentifierStepCount') {
                dataMap.steps.push(recordData);
            } else if (type === 'HKQuantityTypeIdentifierHeartRate') {
                dataMap.heartRate.push(recordData);
            } else if (type === 'HKCategoryTypeIdentifierSleepAnalysis') {
                const start = new Date(startDate);
                const end = new Date(endDate);
                const hours = (end - start) / (1000 * 60 * 60);
                dataMap.sleep.push({ ...recordData, value: hours });
            } else if (type === 'HKQuantityTypeIdentifierActiveEnergyBurned') {
                dataMap.activeEnergy.push(recordData);
            } else if (type === 'HKQuantityTypeIdentifierBodyMass') {
                dataMap.weight.push(recordData);
            }
        }

        // Save to database
        for (const [type, records] of Object.entries(dataMap)) {
            await this.saveData('healthData', { type, records });
            this.healthData[type] = records;
        }

        // Parse workouts
        const workouts = xmlDoc.getElementsByTagName('Workout');
        const workoutData = [];

        for (let i = 0; i < workouts.length; i++) {
            const workout = workouts[i];
            workoutData.push({
                type: workout.getAttribute('workoutActivityType'),
                duration: parseFloat(workout.getAttribute('duration')),
                date: workout.getAttribute('startDate').split(' ')[0],
                startDate: workout.getAttribute('startDate'),
                endDate: workout.getAttribute('endDate')
            });
        }

        await this.saveData('healthData', { type: 'workouts', records: workoutData });
        this.healthData.workouts = workoutData;
    }

    // Chart
    updateChart() {
        const metric = document.getElementById('metricSelect').value;
        const period = parseInt(document.getElementById('periodSelect').value);

        const endDate = new Date();
        const startDate = new Date(endDate.getTime() - (period * 24 * 60 * 60 * 1000));

        const data = this.aggregateDataByDay(this.healthData[metric], startDate, endDate);

        const ctx = document.getElementById('trendChart');

        if (this.chart) {
            this.chart.destroy();
        }

        const labels = data.map(d => {
            const date = new Date(d.date);
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        });

        const values = data.map(d => d.value);

        this.chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: this.getMetricLabel(metric),
                    data: values,
                    borderColor: '#FF2D55',
                    backgroundColor: 'rgba(255, 45, 85, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    aggregateDataByDay(records, startDate, endDate) {
        const dataMap = new Map();

        records.forEach(record => {
            const recordDate = new Date(record.date);
            if (recordDate >= startDate && recordDate <= endDate) {
                const dateKey = record.date;
                if (!dataMap.has(dateKey)) {
                    dataMap.set(dateKey, { date: dateKey, value: 0, count: 0 });
                }
                const entry = dataMap.get(dateKey);
                entry.value += record.value;
                entry.count += 1;
            }
        });

        const result = Array.from(dataMap.values()).map(entry => ({
            date: entry.date,
            value: entry.value / (entry.count > 1 ? entry.count : 1)
        }));

        return result.sort((a, b) => new Date(a.date) - new Date(b.date));
    }

    getMetricLabel(metric) {
        const labels = {
            steps: 'Steps',
            heartRate: 'Heart Rate (bpm)',
            sleep: 'Sleep (hours)',
            activeEnergy: 'Active Calories'
        };
        return labels[metric] || metric;
    }

    // Insights
    async generateInsights() {
        document.getElementById('loadingOverlay').classList.add('active');

        setTimeout(() => {
            const insights = window.healthInsights.generateInsights(this.healthData);
            this.displayInsights(insights);
            document.getElementById('loadingOverlay').classList.remove('active');
        }, 1000);
    }

    displayInsights(insights) {
        const container = document.getElementById('insightCards');
        container.innerHTML = '';

        insights.forEach(insight => {
            const card = document.createElement('div');
            card.className = `insight-card ${insight.type}`;
            card.innerHTML = `
                <h4>${insight.icon} ${insight.title}</h4>
                <p>${insight.message}</p>
            `;
            container.appendChild(card);
        });

        document.getElementById('insightsContent').innerHTML =
            '<p>✨ Analysis complete! See your personalized insights below.</p>';
    }

    async checkDailyInsights() {
        const lastInsightDate = localStorage.getItem('lastInsightDate');
        const today = new Date().toISOString().split('T')[0];

        if (lastInsightDate !== today && this.healthData.steps.length > 0) {
            // Generate automatic daily insights
            const insights = window.healthInsights.generateDailyInsights(this.healthData);
            if (insights.length > 0) {
                localStorage.setItem('lastInsightDate', today);
                // You could show a notification here
                console.log('Daily insights ready:', insights);
            }
        }
    }

    // Data Management
    async exportData() {
        const exportData = {
            healthData: this.healthData,
            exportDate: new Date().toISOString()
        };

        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `health-insights-export-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }

    async clearAllData() {
        if (confirm('Are you sure you want to clear all health data? This cannot be undone.')) {
            const transaction = this.db.transaction(['healthData'], 'readwrite');
            const store = transaction.objectStore('healthData');
            await store.clear();

            this.healthData = {
                steps: [],
                heartRate: [],
                sleep: [],
                activeEnergy: [],
                weight: [],
                workouts: []
            };

            this.updateUI();
            this.closeModal('settingsModal');
            alert('All data cleared successfully');
        }
    }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.healthApp = new HealthApp();
    });
} else {
    window.healthApp = new HealthApp();
}
