# 🤖 AI Chat Insights Feature Guide

## Overview

The Health Insights app now features a **conversational AI interface** powered by Claude 3.5 Sonnet. Instead of static insights, you can have natural conversations about your health data!

---

## 🎯 Key Features

### 1. Chat Interface
- **iMessage-style design** with bubble messages
- **User messages**: Pink bubbles on the right
- **AI responses**: Gray bubbles on the left
- **Timestamps** on every message
- **Auto-scrolling** to latest messages
- **Text selection** enabled for copying insights

### 2. Preset Questions (Quick Start)
Five one-tap questions to get started:

| Icon | Question | What It Does |
|------|----------|-------------|
| 🚶 | How's my activity level? | Analyzes your steps and daily goals |
| 😴 | Sleep quality | Reviews your sleep patterns |
| ❤️ | Heart health | Checks cardiovascular metrics |
| 📊 | Weekly trends | Identifies patterns over 7 days |
| 💡 | Recommendations | Provides top 3 health tips |

### 3. Natural Language Understanding
Ask anything! Examples:
- "Why am I so tired lately?"
- "Is my heart rate normal?"
- "Should I workout today?"
- "How can I sleep better?"
- "Compare this week to last week"
- "What's causing my low energy?"

### 4. Automatic Health Context
Claude automatically receives:
- **Today's Stats**: Steps, heart rate, sleep, calories
- **7-Day Averages**: All key metrics
- **Recent Workouts**: Type, duration, calories
- **Trends**: Patterns and changes

### 5. Chat History
- **Persistent**: Saves across app restarts
- **Chronological**: All conversations preserved
- **Searchable**: Find old insights
- **Clearable**: Reset anytime via settings menu

---

## 📱 User Experience Flow

### First Time Setup

```
1. Open App → Tap "AI Insights" tab (✨)
   ↓
2. See welcome screen
   "AI Health Insights - Ask me anything!"
   ↓
3. Tap "Set Up API Key"
   ↓
4. Enter Claude API key from console.anthropic.com
   ↓
5. Save → Ready to chat!
```

### Regular Usage

```
1. Open "AI Insights" tab
   ↓
2. See chat history (if any)
   ↓
3. Choose:
   • Tap preset question button, OR
   • Type custom question in text field
   ↓
4. Send message (tap arrow button)
   ↓
5. Watch loading indicator
   "Analyzing your health data..."
   ↓
6. Receive AI response with insights!
   ↓
7. Continue conversation or ask follow-up
```

---

## 🎨 Interface Design

### Welcome Screen (First Visit)
```
┌─────────────────────────────────────┐
│         🧠                           │
│    AI Health Insights                │
│                                      │
│  Ask me anything about your health   │
│  data! I'll analyze your steps,      │
│  heart rate, sleep, and activity.    │
└─────────────────────────────────────┘
```

### Preset Questions (Horizontal Scroll)
```
┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
│  🚶  │  │  😴  │  │  ❤️  │  │  📊  │  │  💡  │
│Activity│ │Sleep │  │Heart │  │Trends│  │ Tips │
└──────┘  └──────┘  └──────┘  └──────┘  └──────┘
```

### Chat Messages
```
                    ┌──────────────────┐
                    │ How's my sleep?  │
                    │     10:30 AM     │
                    └──────────────────┘

┌──────────────────────────────────────┐
│ Looking at your data, you're         │
│ averaging 7.2 hours per night this   │
│ week. That's within the optimal      │
│ 7-9 hour range! Your sleep quality   │
│ has been consistent. Keep it up! 😴  │
│              10:30 AM                │
└──────────────────────────────────────┘
```

### Input Area
```
┌─────────────────────────────────────────┐
│ [Type your question here...        ] 🔴 │
└─────────────────────────────────────────┘
```

---

## 🔐 Privacy & Security

### Data Flow
1. **Local Collection**: Health data fetched from HealthKit
2. **Context Building**: Data formatted into markdown
3. **Secure Transmission**: Sent to Anthropic via HTTPS
4. **API Processing**: Claude analyzes and responds
5. **Local Storage**: Messages saved on device only

### What's Sent to Claude API
- Current health metrics (today + 7-day averages)
- Recent workout history
- Your questions
- Previous conversation history (last 10 messages)

### What's NOT Sent
- Your name or personal identity
- Location data
- Device information
- Full historical data (only summaries)

### API Key Security
- Stored locally in `UserDefaults`
- Never transmitted except as auth header
- Can be changed/deleted anytime
- Not stored in iCloud or backups

### Anthropic's Privacy Promise
- **No training on API data**: Your health data won't train future models
- **No data retention**: Messages not stored after response
- **HIPAA-ready infrastructure**: Enterprise-grade security

---

## 💬 Example Conversations

### Conversation 1: Activity Analysis
```
You: How's my activity level?

Claude: Looking at your data, you're averaging 8,500 steps per day
this week 🚶. That's really good! You're close to the 10,000 step
goal. I noticed your most active day was Tuesday with 12,000 steps.

Your active calorie burn is also strong at 450 kcal/day. To hit
10,000 steps consistently, try adding a 15-minute walk after lunch.
Keep up the great work! 💪

You: Why was Tuesday so high?

Claude: Let me check your workout data... I see you had a 45-minute
running session on Tuesday (380 kcal burned). That definitely
contributed to the higher step count! Running is excellent for both
cardiovascular health and step goals. 🏃
```

### Conversation 2: Sleep Concerns
```
You: I've been really tired. What's wrong?

Claude: Let me analyze your recent patterns... I see a few factors:

1. **Sleep Duration**: You're averaging 6.2 hours over the past week,
   which is below the recommended 7-9 hours. You're accumulating
   sleep debt. 😴

2. **Consistency**: Your sleep times vary significantly (5.5h to 7h),
   which can disrupt your circadian rhythm.

3. **Activity Impact**: Despite lower sleep, your activity remains
   high (9,000 steps/day), which might be adding to fatigue.

**Recommendations:**
- Aim for 7.5 hours minimum tonight
- Try to sleep/wake at consistent times
- Consider an extra rest day this week

Your resting heart rate is slightly elevated (68 vs usual 62), which
also suggests your body needs more recovery.

You: Should I skip my workout today?

Claude: Given your elevated resting HR and sleep debt, I'd recommend
either taking today as a rest day or doing very light activity like
a gentle walk. Your body needs recovery time. Tomorrow, after better
sleep, you'll perform better anyway! 🌟
```

### Conversation 3: Weekly Progress
```
You: What are the key trends this week?

Claude: Great question! Here's your weekly breakdown:

**Positive Trends** ✅
- Steps increased 15% (7,800 → 9,000 avg)
- Workout consistency: 4 sessions (up from 2)
- Active calories up 20% (380 → 450 kcal/day)

**Areas to Watch** ⚠️
- Sleep decreased 8% (7.0 → 6.4 hours avg)
- Resting heart rate elevated by 5 bpm

**Insight**: Your increased activity is excellent, but it's coming
at the cost of sleep. Your body needs that recovery time to adapt
to the higher training load.

**This Week's Focus**:
1. Maintain the awesome activity level 💪
2. Prioritize 7+ hours of sleep 😴
3. Consider 1-2 rest days for recovery

You're making great progress overall! 🎉
```

---

## 🔧 Technical Implementation

### Architecture
```
ChatInsightsView (UI)
        ↓
ClaudeAPIManager (Logic)
        ↓
URLSession (Networking)
        ↓
Anthropic API (Claude)
```

### Data Models
```swift
struct ChatMessage {
    var id: UUID
    let role: MessageRole  // .user or .assistant
    let content: String
    let timestamp: Date
}

enum MessageRole: String {
    case user
    case assistant
}
```

### API Request Flow
```
1. User sends message
2. Build health context from HealthKit data
3. Construct API request with:
   - System prompt (health specialist role)
   - Health data context
   - Conversation history
   - User's question
4. Send POST to api.anthropic.com/v1/messages
5. Parse response
6. Display AI message
7. Save to chat history
```

### System Prompt
```
You are a health insights assistant analyzing Apple Health data.
You provide personalized, evidence-based health insights and answer
questions about the user's health metrics.

Guidelines:
- Be encouraging and supportive
- Reference specific data points when making observations
- Provide actionable recommendations
- Mention when medical consultation may be needed
- Focus on trends and patterns
- Use emojis appropriately for engagement
```

---

## 💰 Cost Considerations

### Claude API Pricing
- **Model**: Claude 3.5 Sonnet
- **Input**: $3 per million tokens
- **Output**: $15 per million tokens

### Typical Usage Costs
- **Average message**: ~500 input tokens + ~300 output tokens
- **Cost per message**: ~$0.006 (less than a penny!)
- **100 messages**: ~$0.60
- **Monthly (300 messages)**: ~$1.80

### Free Tier
- Anthropic offers **$5 free credit** for new accounts
- Covers ~800 conversations!
- Perfect for personal use

### Cost Optimization
- Context is reused across messages
- Only last 10 messages in history sent
- Health data sent as concise markdown
- Max tokens capped at 1024

---

## 🚀 Future Enhancements

Potential additions:
- [ ] Voice input for questions
- [ ] Export insights as PDF reports
- [ ] Weekly summary emails
- [ ] Custom system prompts
- [ ] Multi-language support
- [ ] Integration with Apple Health Journal
- [ ] Comparison with population averages
- [ ] Goal setting and tracking
- [ ] Medication tracking integration
- [ ] Mental health mood tracking

---

## ⚠️ Limitations

### Current Constraints
- **Requires internet**: Can't work offline
- **Requires API key**: User must have Anthropic account
- **Cost**: Not free (though very affordable)
- **Data sharing**: Health data sent to Anthropic
- **No voice**: Text-only currently
- **Rate limits**: Subject to API rate limits

### Not a Medical Device
This app is **for informational purposes only**:
- Not FDA approved
- Not a replacement for medical advice
- Cannot diagnose conditions
- Should not replace doctor visits
- Emergency symptoms require 911

---

## 📞 Support

### Troubleshooting

**"API Key Invalid"**
- Check key format (starts with `sk-ant-api03-`)
- Verify key at console.anthropic.com
- Ensure billing is set up

**"No Response"**
- Check internet connection
- Verify API rate limits
- Try shorter questions
- Check Anthropic status page

**"Error Processing"**
- Ensure HealthKit permissions granted
- Restart app
- Clear chat history
- Reinstall if needed

---

**Ready to start chatting?** Open the app and tap the AI Insights tab! ✨
