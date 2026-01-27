# Testing the AI Health Coach Agent

This guide shows you how to test the AI health coach with mockup data before running the full iOS app.

## Prerequisites

- Python 3.6 or higher
- `requests` library
- OpenRouter API key

## Setup

1. Install the required Python package:
```bash
pip install requests
```

2. Edit `test_health_agent.py` and add your OpenRouter API key on line 14:
```python
API_KEY = "sk-or-v1-your-actual-key-here"  # Replace with your actual key
```

Get your API key from: https://openrouter.ai/keys

## Running the Tests

Run the test script:
```bash
python3 test_health_agent.py
```

## What the Tests Do

### Test 1: Proactive Morning Greeting
- Simulates a user opening the app in the morning
- Sends mockup health data including:
  - Steps: 8,234 steps
  - Sleep: 5.5 hours (down from 7.2 hours - declining trend)
  - Heart rate, exercise, water intake, etc.
- Tests if the AI:
  - Greets the user personally
  - Notices the poor sleep
  - Mentions specific metrics
  - Asks relevant questions
  - Uses a supportive tone

### Test 2: Diagnostic Follow-up
- Tests multi-turn conversation capability
- Simulates a user responding to the AI's questions
- Tests if the AI:
  - Acknowledges user feedback
  - Provides recommendations
  - Shows empathy
  - Gives actionable advice

## Understanding the Results

The test will show:
- ✓ marks for passed checks
- ✗ marks for failed checks
- The full AI response
- Analysis of response quality

## Mockup Health Data

The test uses realistic health data that shows some concerns:
- **Poor sleep**: 5.5 hours (down from 7.2)
- **Moderate activity**: 8,234 steps
- **Low water intake**: 1.2L
- **Normal heart rate**: 78 bpm average

This data should trigger the AI to notice the sleep issue and ask follow-up questions.

## Expected Behavior

A successful test should show the AI:
1. Greeting "Mor" by name
2. Noticing the declined sleep (5.5 hours vs 7.2 hours)
3. Asking about why sleep declined
4. Providing helpful recommendations
5. Being warm and supportive

## Troubleshooting

**"API_KEY not set" error:**
- Make sure you replaced `YOUR_OPENROUTER_API_KEY_HERE` with your actual key

**Connection errors:**
- Check your internet connection
- Verify your API key is valid at https://openrouter.ai/keys

**"Rate limit" errors:**
- Wait a minute and try again
- OpenRouter has rate limits on free tier

**Empty responses:**
- The model may be thinking (reasoning mode takes longer)
- Increase the timeout if needed

## Next Steps

Once tests pass, you can:
1. Add your API key to `ClaudeAPIManager.swift` in the iOS app
2. Build and run the app in Xcode
3. The app will work the same way as these tests!
