// Health Insights Engine

class HealthInsights {
    constructor() {
        this.insights = [];
    }

    generateInsights(healthData) {
        this.insights = [];

        // Analyze different health metrics
        this.analyzeSteps(healthData.steps);
        this.analyzeHeartRate(healthData.heartRate);
        this.analyzeSleep(healthData.sleep);
        this.analyzeActivity(healthData.activeEnergy, healthData.workouts);
        this.analyzeWeeklyTrends(healthData);
        this.analyzePatternsAndCorrelations(healthData);

        return this.insights;
    }

    generateDailyInsights(healthData) {
        this.insights = [];
        const today = new Date().toISOString().split('T')[0];
        const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

        // Compare today vs yesterday
        const todaySteps = this.sumValuesByDate(healthData.steps, today);
        const yesterdaySteps = this.sumValuesByDate(healthData.steps, yesterday);

        if (todaySteps > yesterdaySteps) {
            this.addInsight('positive', '📈 Progress', `You're ${Math.round(((todaySteps - yesterdaySteps) / yesterdaySteps) * 100)}% more active than yesterday!`);
        }

        // Sleep quality
        const lastNightSleep = this.sumValuesByDate(healthData.sleep, yesterday);
        if (lastNightSleep < 6) {
            this.addInsight('warning', '😴 Sleep Alert', `You only got ${lastNightSleep.toFixed(1)} hours of sleep last night. Aim for 7-9 hours.`);
        } else if (lastNightSleep >= 7 && lastNightSleep <= 9) {
            this.addInsight('positive', '✨ Well Rested', `Great sleep! You got ${lastNightSleep.toFixed(1)} hours last night.`);
        }

        return this.insights;
    }

    analyzeSteps(stepsData) {
        if (stepsData.length === 0) return;

        const last7Days = this.getLastNDays(stepsData, 7);
        const last30Days = this.getLastNDays(stepsData, 30);

        // Calculate averages
        const avg7Days = this.calculateDailyAverage(last7Days);
        const avg30Days = this.calculateDailyAverage(last30Days);

        // WHO recommends 10,000 steps per day
        const dailyGoal = 10000;

        if (avg7Days >= dailyGoal) {
            this.addInsight('positive', '🎯 Step Goal Champion',
                `Amazing! You're averaging ${Math.round(avg7Days).toLocaleString()} steps per day this week, exceeding the recommended 10,000 steps.`);
        } else if (avg7Days >= dailyGoal * 0.7) {
            this.addInsight('info', '👟 Almost There',
                `You're averaging ${Math.round(avg7Days).toLocaleString()} steps per day. Just ${Math.round(dailyGoal - avg7Days).toLocaleString()} more steps to reach the daily goal!`);
        } else {
            this.addInsight('warning', '🚶 Step It Up',
                `Your current average is ${Math.round(avg7Days).toLocaleString()} steps per day. Try to increase your daily movement to reach 10,000 steps.`);
        }

        // Trend analysis
        if (avg7Days > avg30Days * 1.1) {
            this.addInsight('positive', '📈 Trending Up',
                `Great momentum! Your activity has increased by ${Math.round(((avg7Days - avg30Days) / avg30Days) * 100)}% compared to your monthly average.`);
        } else if (avg7Days < avg30Days * 0.9) {
            this.addInsight('warning', '📉 Activity Dip',
                `Your step count is down ${Math.round(((avg30Days - avg7Days) / avg30Days) * 100)}% this week. Let's get moving!`);
        }

        // Consistency
        const consistency = this.calculateConsistency(last7Days);
        if (consistency > 0.8) {
            this.addInsight('positive', '🎖️ Consistency Master',
                `You've been remarkably consistent with your daily activity. Keep up the great routine!`);
        }
    }

    analyzeHeartRate(heartRateData) {
        if (heartRateData.length < 50) return;

        const last7Days = this.getLastNDays(heartRateData, 7);
        const avgHR = this.calculateAverage(last7Days.map(r => r.value));
        const minHR = Math.min(...last7Days.map(r => r.value));
        const maxHR = Math.max(...last7Days.map(r => r.value));

        // Resting heart rate insights (assuming lowest values are resting)
        const restingHR = Math.round(minHR);

        if (restingHR < 60) {
            this.addInsight('positive', '💪 Athletic Heart',
                `Your resting heart rate of ${restingHR} bpm indicates excellent cardiovascular fitness!`);
        } else if (restingHR >= 60 && restingHR <= 100) {
            this.addInsight('info', '💓 Healthy Heart',
                `Your resting heart rate of ${restingHR} bpm is within the normal range (60-100 bpm).`);
        } else {
            this.addInsight('warning', '⚠️ Heart Rate Alert',
                `Your resting heart rate of ${restingHR} bpm is above normal. Consider consulting with a healthcare provider.`);
        }

        // Heart rate variability
        const hrVariability = maxHR - minHR;
        if (hrVariability > 80) {
            this.addInsight('info', '🏃 Active Lifestyle',
                `Your heart rate varies between ${Math.round(minHR)} and ${Math.round(maxHR)} bpm, showing you engage in various activity levels.`);
        }
    }

    analyzeSleep(sleepData) {
        if (sleepData.length === 0) return;

        const last7Days = this.getLastNDays(sleepData, 7);
        const avgSleep = this.calculateDailyAverage(last7Days);

        // Sleep recommendations: 7-9 hours
        if (avgSleep >= 7 && avgSleep <= 9) {
            this.addInsight('positive', '😴 Sleep Champion',
                `Perfect! You're averaging ${avgSleep.toFixed(1)} hours of sleep per night, which is in the optimal range.`);
        } else if (avgSleep < 7) {
            const deficit = 7 - avgSleep;
            this.addInsight('warning', '⏰ Sleep Debt',
                `You're averaging ${avgSleep.toFixed(1)} hours of sleep. Try to get ${deficit.toFixed(1)} more hours per night for optimal health.`);
        } else {
            this.addInsight('info', '🛌 Long Sleeper',
                `You're averaging ${avgSleep.toFixed(1)} hours of sleep. While this might work for you, most adults need 7-9 hours.`);
        }

        // Sleep consistency
        const sleepTimes = last7Days.map(r => r.value);
        const stdDev = this.calculateStdDev(sleepTimes);

        if (stdDev < 0.5) {
            this.addInsight('positive', '📅 Consistent Schedule',
                `Great job maintaining a consistent sleep schedule! This helps improve sleep quality.`);
        } else if (stdDev > 1.5) {
            this.addInsight('warning', '⏱️ Irregular Sleep',
                `Your sleep duration varies significantly. Try to maintain a more consistent sleep schedule.`);
        }
    }

    analyzeActivity(energyData, workoutData) {
        if (energyData.length === 0) return;

        const last7Days = this.getLastNDays(energyData, 7);
        const avgCalories = this.calculateDailyAverage(last7Days);

        // Active energy recommendations (varies by person, using general guidelines)
        if (avgCalories >= 500) {
            this.addInsight('positive', '🔥 Highly Active',
                `Excellent! You're burning an average of ${Math.round(avgCalories)} active calories per day.`);
        } else if (avgCalories >= 300) {
            this.addInsight('info', '💪 Moderately Active',
                `You're burning ${Math.round(avgCalories)} active calories daily. Great work staying active!`);
        } else {
            this.addInsight('warning', '🏃 Boost Your Activity',
                `Try to increase your activity level to burn more calories throughout the day.`);
        }

        // Workout frequency
        if (workoutData && workoutData.length > 0) {
            const last7Workouts = this.getLastNDays(workoutData, 7);
            const workoutsPerWeek = this.countUniqueDay(last7Workouts);

            if (workoutsPerWeek >= 5) {
                this.addInsight('positive', '🏆 Fitness Enthusiast',
                    `Amazing dedication! You've worked out ${workoutsPerWeek} times this week.`);
            } else if (workoutsPerWeek >= 3) {
                this.addInsight('positive', '💯 Active Week',
                    `Great job! ${workoutsPerWeek} workouts this week keeps you on track for fitness goals.`);
            } else if (workoutsPerWeek > 0) {
                this.addInsight('info', '🎯 Room to Grow',
                    `You had ${workoutsPerWeek} workout${workoutsPerWeek > 1 ? 's' : ''} this week. Aim for at least 3-5 sessions per week.`);
            }
        }
    }

    analyzeWeeklyTrends(healthData) {
        const stepsLastWeek = this.getLastNDays(healthData.steps, 7);
        const stepsPreviousWeek = this.getLastNDays(healthData.steps, 14).slice(0, 7);

        if (stepsLastWeek.length > 0 && stepsPreviousWeek.length > 0) {
            const avgLast = this.calculateDailyAverage(stepsLastWeek);
            const avgPrevious = this.calculateDailyAverage(stepsPreviousWeek);
            const change = ((avgLast - avgPrevious) / avgPrevious) * 100;

            if (Math.abs(change) > 10) {
                if (change > 0) {
                    this.addInsight('positive', '🚀 Weekly Progress',
                        `Your activity increased by ${Math.round(change)}% compared to last week!`);
                } else {
                    this.addInsight('warning', '📊 Weekly Dip',
                        `Your activity decreased by ${Math.round(Math.abs(change))}% this week. Let's bounce back!`);
                }
            }
        }
    }

    analyzePatternsAndCorrelations(healthData) {
        // Analyze relationship between sleep and activity
        if (healthData.sleep.length > 7 && healthData.steps.length > 7) {
            const last7Days = this.getLast7DaysSummary(healthData);

            if (last7Days.length >= 5) {
                const correlation = this.calculateCorrelation(
                    last7Days.map(d => d.sleep),
                    last7Days.map(d => d.steps)
                );

                if (correlation > 0.5) {
                    this.addInsight('info', '🔄 Sleep & Activity Link',
                        `Your data shows better sleep correlates with more activity the next day. Keep prioritizing rest!`);
                } else if (correlation < -0.5) {
                    this.addInsight('info', '💡 Rest & Recovery',
                        `Your activity levels seem to affect your sleep. Consider rest days for better recovery.`);
                }
            }
        }

        // Weekend vs Weekday patterns
        const weekdaySteps = this.getWeekdayVsWeekend(healthData.steps, 'weekday');
        const weekendSteps = this.getWeekdayVsWeekend(healthData.steps, 'weekend');

        if (weekdaySteps.length > 0 && weekendSteps.length > 0) {
            const avgWeekday = this.calculateAverage(weekdaySteps.map(r => r.value));
            const avgWeekend = this.calculateAverage(weekendSteps.map(r => r.value));

            if (avgWeekend < avgWeekday * 0.7) {
                this.addInsight('warning', '📅 Weekend Slump',
                    `Your weekend activity is significantly lower. Try to stay active on weekends too!`);
            } else if (avgWeekend > avgWeekday * 1.2) {
                this.addInsight('positive', '🎉 Active Weekends',
                    `You're more active on weekends! Great way to balance a busy work week.`);
            }
        }
    }

    // Helper Methods
    addInsight(type, title, message) {
        const icons = {
            positive: '✅',
            warning: '⚠️',
            info: 'ℹ️'
        };

        this.insights.push({
            type,
            title,
            message,
            icon: icons[type] || 'ℹ️',
            timestamp: new Date().toISOString()
        });
    }

    getLastNDays(data, days) {
        const cutoffDate = new Date(Date.now() - (days * 24 * 60 * 60 * 1000));
        return data.filter(record => {
            const recordDate = new Date(record.date);
            return recordDate >= cutoffDate;
        });
    }

    sumValuesByDate(data, date) {
        return data
            .filter(r => r.date === date)
            .reduce((sum, r) => sum + r.value, 0);
    }

    calculateDailyAverage(data) {
        if (data.length === 0) return 0;

        const dateMap = new Map();
        data.forEach(record => {
            if (!dateMap.has(record.date)) {
                dateMap.set(record.date, 0);
            }
            dateMap.set(record.date, dateMap.get(record.date) + record.value);
        });

        const dailyTotals = Array.from(dateMap.values());
        return dailyTotals.reduce((sum, val) => sum + val, 0) / dailyTotals.length;
    }

    calculateAverage(values) {
        if (values.length === 0) return 0;
        return values.reduce((sum, val) => sum + val, 0) / values.length;
    }

    calculateStdDev(values) {
        if (values.length === 0) return 0;
        const avg = this.calculateAverage(values);
        const squareDiffs = values.map(value => Math.pow(value - avg, 2));
        const avgSquareDiff = this.calculateAverage(squareDiffs);
        return Math.sqrt(avgSquareDiff);
    }

    calculateConsistency(data) {
        if (data.length === 0) return 0;

        const dateMap = new Map();
        data.forEach(record => {
            if (!dateMap.has(record.date)) {
                dateMap.set(record.date, 0);
            }
            dateMap.set(record.date, dateMap.get(record.date) + record.value);
        });

        const dailyTotals = Array.from(dateMap.values());
        const avg = this.calculateAverage(dailyTotals);
        const stdDev = this.calculateStdDev(dailyTotals);

        // Lower coefficient of variation = higher consistency
        const coefficientOfVariation = stdDev / avg;
        return Math.max(0, 1 - coefficientOfVariation);
    }

    countUniqueDays(data) {
        const dates = new Set(data.map(record => record.date));
        return dates.size;
    }

    getLast7DaysSummary(healthData) {
        const summary = [];
        for (let i = 0; i < 7; i++) {
            const date = new Date(Date.now() - (i * 24 * 60 * 60 * 1000)).toISOString().split('T')[0];
            summary.push({
                date,
                steps: this.sumValuesByDate(healthData.steps, date),
                sleep: this.sumValuesByDate(healthData.sleep, date),
                calories: this.sumValuesByDate(healthData.activeEnergy, date)
            });
        }
        return summary.reverse();
    }

    calculateCorrelation(x, y) {
        if (x.length !== y.length || x.length === 0) return 0;

        const n = x.length;
        const sumX = x.reduce((a, b) => a + b, 0);
        const sumY = y.reduce((a, b) => a + b, 0);
        const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
        const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0);
        const sumY2 = y.reduce((sum, yi) => sum + yi * yi, 0);

        const numerator = n * sumXY - sumX * sumY;
        const denominator = Math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

        return denominator === 0 ? 0 : numerator / denominator;
    }

    getWeekdayVsWeekend(data, type) {
        return data.filter(record => {
            const day = new Date(record.date).getDay();
            const isWeekend = day === 0 || day === 6;
            return type === 'weekend' ? isWeekend : !isWeekend;
        });
    }
}

// Initialize global insights engine
window.healthInsights = new HealthInsights();
