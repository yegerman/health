# 💚 Health Insights - iPhone Web App

A Progressive Web App (PWA) that syncs with Apple Health data to provide personalized daily and on-demand health insights.

## Features

### 📊 Core Functionality
- **Apple Health Integration**: Import your complete health data from Apple Health
- **Daily Dashboard**: View your steps, heart rate, sleep, and active calories at a glance
- **Health Insights Engine**: AI-powered analysis of your health patterns and trends
- **Interactive Charts**: Visualize your health metrics over time (7, 14, or 30 days)
- **On-Demand Analysis**: Generate personalized insights whenever you need them
- **Offline Support**: Works offline after installation thanks to PWA technology

### 🎯 Health Metrics Tracked
- Steps count
- Heart rate (average, min, max, resting)
- Sleep duration and quality
- Active energy (calories burned)
- Body weight
- Workouts and activity sessions

### 💡 Intelligent Insights
The app analyzes your data to provide:
- Activity level assessments
- Sleep quality analysis
- Heart health indicators
- Weekly trend comparisons
- Consistency tracking
- Pattern recognition (e.g., weekday vs weekend activity)
- Correlations (e.g., sleep impact on next-day activity)
- Personalized recommendations

## Getting Started

### Prerequisites
- An iPhone with Apple Health data
- A modern web browser (Safari, Chrome, Firefox)
- Your Apple Health export file

### Installation

#### Option 1: Use as Web App
1. Clone or download this repository
2. Serve the files using any web server:
   ```bash
   # Using Python
   python3 -m http.server 8000

   # Using Node.js
   npx serve

   # Using PHP
   php -S localhost:8000
   ```
3. Open `http://localhost:8000` in your browser

#### Option 2: Deploy to Web Hosting
1. Upload all files to your web hosting service (GitHub Pages, Netlify, Vercel, etc.)
2. Access via the provided URL
3. Add to your iPhone home screen for app-like experience

#### Option 3: Install as PWA on iPhone
1. Open the app in Safari on your iPhone
2. Tap the Share button
3. Scroll down and tap "Add to Home Screen"
4. Tap "Add" in the top-right corner
5. The app will appear on your home screen like a native app

## How to Export Apple Health Data

Follow these steps to export your health data from Apple Health:

1. **Open the Health app** on your iPhone
2. **Tap your profile picture** or initials in the top-right corner
3. **Scroll down** to the bottom of the screen
4. **Tap "Export All Health Data"**
5. **Tap "Export"** and wait (this may take a few minutes)
6. **Save the file** to Files, iCloud Drive, or share it
7. **Transfer to your device**:
   - AirDrop to your Mac
   - Email to yourself
   - Save to iCloud and download on your computer
8. **Extract the ZIP file** to get `export.xml`

### Important Notes:
- The export file can be large (several MB to GB depending on your data)
- Export includes all your health data from all time
- The file is in XML format and contains detailed records
- Your data stays local - nothing is uploaded to any server

## Using the App

### Dashboard
- View today's key health metrics
- See a daily summary of your activity
- Quick access to import data

### Insights Tab
1. Click **"Generate Insights"** to analyze your health data
2. Review personalized recommendations and observations
3. Insights are categorized as:
   - ✅ **Positive**: Things you're doing well
   - ⚠️ **Warnings**: Areas needing attention
   - ℹ️ **Info**: Interesting patterns and observations

### Trends Tab
- Select a metric (Steps, Heart Rate, Sleep, Calories)
- Choose a time period (7, 14, or 30 days)
- View interactive charts showing your progress

### Settings
- Set daily insight notification time
- Export your processed data
- Clear all data if needed

## Technical Details

### Technologies Used
- **HTML5**: Semantic markup and structure
- **CSS3**: Modern, responsive design with iOS-optimized styling
- **Vanilla JavaScript**: No framework dependencies, lightweight and fast
- **IndexedDB**: Local data storage for offline access
- **Chart.js**: Beautiful, interactive charts
- **Service Workers**: Offline functionality and caching
- **Web App Manifest**: PWA installation support

### Browser Support
- Safari 14+ (iOS 14+)
- Chrome 90+
- Firefox 88+
- Edge 90+

### Data Privacy
- **100% Local**: All data processing happens on your device
- **No Server**: No data is sent to any remote server
- **No Tracking**: No analytics or tracking scripts
- **Your Data, Your Control**: Export or delete anytime

## File Structure

```
health-insights/
├── index.html          # Main app interface
├── styles.css          # Responsive styling
├── app.js              # Core application logic
├── insights.js         # Health insights engine
├── manifest.json       # PWA manifest
├── service-worker.js   # Offline support
├── icon-192.png        # App icon (192x192)
├── icon-512.png        # App icon (512x512)
└── README.md           # This file
```

## Features Breakdown

### Dashboard Stats
The dashboard automatically updates to show:
- **Steps**: Total steps taken today
- **Heart Rate**: Average heart rate (BPM)
- **Sleep**: Hours and minutes of sleep from last night
- **Calories**: Active calories burned today

### Insights Engine
The insights engine analyzes:

1. **Step Analysis**
   - Comparison to 10,000 step goal
   - 7-day vs 30-day trends
   - Consistency scoring
   - Progress tracking

2. **Heart Rate Analysis**
   - Resting heart rate assessment
   - Heart rate variability
   - Cardiovascular fitness indicators

3. **Sleep Analysis**
   - Duration recommendations (7-9 hours)
   - Sleep consistency patterns
   - Sleep debt calculations

4. **Activity Analysis**
   - Active calorie burn rates
   - Workout frequency tracking
   - Activity level classification

5. **Pattern Recognition**
   - Weekday vs weekend comparisons
   - Sleep-activity correlations
   - Weekly trend analysis

### Chart Visualization
Interactive line charts with:
- Smooth animations
- Touch-friendly controls
- Multiple time periods
- Automatic scaling
- Data aggregation by day

## Development

### Local Development Setup
```bash
# Clone the repository
git clone <repository-url>
cd health

# Start a local server
python3 -m http.server 8000

# Open in browser
open http://localhost:8000
```

### Customization
You can customize the app by modifying:
- **styles.css**: Change colors, fonts, layout
- **insights.js**: Adjust insight algorithms and thresholds
- **app.js**: Modify UI behavior and data processing

### Adding New Metrics
To add support for additional health metrics:

1. Add the metric to `healthData` object in `app.js`
2. Update the XML parser to extract the new metric
3. Create analysis functions in `insights.js`
4. Add UI elements in `index.html` and styling in `styles.css`

## Troubleshooting

### Data Not Showing
- Ensure you've imported your Apple Health export file
- Check that the export.xml file is valid and not corrupted
- Try refreshing the page

### Import Failed
- Make sure you're selecting the correct file (export.xml or export.zip)
- Large files may take a while to process - be patient
- Check browser console for specific error messages

### Charts Not Displaying
- Ensure Chart.js library is loaded (check internet connection on first load)
- Try selecting a different time period
- Check that you have data for the selected period

### PWA Not Installing
- Use Safari on iOS for best PWA support
- Ensure you're using HTTPS (required for PWA installation)
- Clear browser cache and try again

## Future Enhancements

Possible future additions:
- [ ] Push notifications for daily insights
- [ ] Goal setting and tracking
- [ ] Custom metric dashboards
- [ ] Data comparison with friends (with privacy controls)
- [ ] Export insights as PDF reports
- [ ] Integration with other health apps
- [ ] Machine learning for better predictions
- [ ] Medication and supplement tracking
- [ ] Mood and mental health tracking

## Performance

- **Initial Load**: ~50KB (without Chart.js)
- **With Data**: Handles 100,000+ health records efficiently
- **Offline**: Full functionality after first load
- **Battery**: Minimal impact, all processing is on-demand

## Security

- No external API calls
- No user authentication required
- All data stored locally in IndexedDB
- No cookies or tracking
- HTTPS recommended for production deployment

## License

This project is open source and available for personal and commercial use.

## Support

For issues, questions, or suggestions:
1. Check the troubleshooting section above
2. Review existing GitHub issues
3. Create a new issue with detailed information

## Acknowledgments

- Apple Health for providing comprehensive health data
- Chart.js for beautiful visualizations
- The PWA community for offline-first best practices

---

**Note**: This app is for informational purposes only and should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always consult with a healthcare provider for medical concerns.

Made with 💚 for better health insights
