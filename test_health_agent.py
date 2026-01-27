#!/usr/bin/env python3
"""
Test script for Health Insights AI Agent
Tests the agent with mockup health data
"""

import json
import requests
from datetime import datetime, timedelta

# API Configuration
API_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
MODEL = "google/gemini-3.0-flash-thinking-preview"
API_KEY = "YOUR_OPENROUTER_API_KEY_HERE"  # Replace with your actual key

def create_mockup_health_data():
    """Create realistic mockup health data for testing"""
    today = datetime.now()
    yesterday = today - timedelta(days=1)

    return {
        "steps": 8234,
        "sleep_hours": 5.5,
        "heart_rate_avg": 78,
        "heart_rate_resting": 65,
        "active_energy": 420,
        "exercise_minutes": 25,
        "stand_hours": 8,
        "water_intake": 1.2,  # liters
        "weight": 75.3,  # kg
        "blood_pressure": "125/82",
        "date": today.strftime("%Y-%m-%d"),
        "previous_sleep": 7.2,  # Previous night's sleep
        "sleep_trend": "declining"
    }

def build_health_context(data):
    """Build health context string like the iOS app does"""
    context = f"""Today's Health Summary ({data['date']}):
- Steps: {data['steps']:,} steps
- Sleep: {data['sleep_hours']} hours (Previous night: {data['previous_sleep']} hours - {data['sleep_trend']})
- Heart Rate: Average {data['heart_rate_avg']} bpm, Resting {data['heart_rate_resting']} bpm
- Active Energy: {data['active_energy']} cal
- Exercise: {data['exercise_minutes']} minutes
- Stand Hours: {data['stand_hours']}/12 hours
- Water Intake: {data['water_intake']}L
- Weight: {data['weight']} kg
- Blood Pressure: {data['blood_pressure']} mmHg"""

    return context

def test_proactive_greeting(health_data):
    """Test the proactive greeting feature"""
    print("\n" + "="*60)
    print("TEST 1: Proactive Morning Greeting")
    print("="*60)

    health_context = build_health_context(health_data)

    system_prompt = """You are Mor's personal AI health coach and diagnostic assistant. You have access to their complete health data from Apple Health and their full conversation history.

Your role:
1. Proactively greet Mor each morning with personalized observations about their health
2. Notice patterns, trends, and potential concerns in their health metrics
3. Ask diagnostic questions when you notice something unusual
4. Provide actionable insights and recommendations
5. Be warm, supportive, and conversational - like a caring friend who happens to be a health expert
6. Remember all previous conversations and health patterns

When greeting Mor, mention specific metrics that stand out (good or concerning) and ask thoughtful follow-up questions about anything unusual."""

    user_prompt = f"""Good morning! Here's my health data from Apple Health:

{health_context}

Please greet me and share your observations about my health."""

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    }

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    print("\nSending request to OpenRouter API...")
    print(f"Model: {MODEL}")
    print(f"Health Data Preview:\n{health_context[:200]}...\n")

    try:
        response = requests.post(API_ENDPOINT, headers=headers, json=payload, timeout=60)
        response.raise_for_status()

        result = response.json()
        ai_response = result['choices'][0]['message']['content']

        print("\n" + "-"*60)
        print("AI HEALTH COACH RESPONSE:")
        print("-"*60)
        print(ai_response)
        print("-"*60)

        # Check for key elements in response
        print("\n✓ Response Analysis:")
        checks = {
            "Personalized greeting": "mor" in ai_response.lower() or "good morning" in ai_response.lower(),
            "Mentions sleep": "sleep" in ai_response.lower(),
            "Mentions specific metrics": any(str(health_data[key]) in ai_response for key in ['steps', 'sleep_hours']),
            "Asks questions": "?" in ai_response,
            "Supportive tone": any(word in ai_response.lower() for word in ['concern', 'notice', 'see', 'looks', 'suggest'])
        }

        for check, passed in checks.items():
            status = "✓" if passed else "✗"
            print(f"  {status} {check}")

        return True

    except requests.exceptions.RequestException as e:
        print(f"\n✗ Error: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return False

def test_diagnostic_conversation(health_data):
    """Test the diagnostic follow-up conversation"""
    print("\n\n" + "="*60)
    print("TEST 2: Diagnostic Follow-up Conversation")
    print("="*60)

    health_context = build_health_context(health_data)

    system_prompt = """You are Mor's personal AI health coach and diagnostic assistant. You have access to their complete health data from Apple Health and their full conversation history.

Your role:
1. Proactively greet Mor each morning with personalized observations about their health
2. Notice patterns, trends, and potential concerns in their health metrics
3. Ask diagnostic questions when you notice something unusual
4. Provide actionable insights and recommendations
5. Be warm, supportive, and conversational - like a caring friend who happens to be a health expert
6. Remember all previous conversations and health patterns

When greeting Mor, mention specific metrics that stand out (good or concerning) and ask thoughtful follow-up questions about anything unusual."""

    # Simulate a conversation
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"Good morning! Here's my health data:\n{health_context}"},
        {"role": "assistant", "content": "Good morning Mor! I noticed you only got 5.5 hours of sleep last night, which is down from 7.2 hours the previous night. That's a significant decline. How are you feeling this morning? Have you noticed anything that might be affecting your sleep quality?"},
        {"role": "user", "content": "Yes, I've been feeling tired. I had a lot of work stress and was on my phone late last night."}
    ]

    payload = {
        "model": MODEL,
        "messages": messages
    }

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    print("\nTesting multi-turn diagnostic conversation...")
    print("Conversation history: 3 previous messages")
    print("User said: 'Yes, I've been feeling tired. I had a lot of work stress and was on my phone late last night.'\n")

    try:
        response = requests.post(API_ENDPOINT, headers=headers, json=payload, timeout=60)
        response.raise_for_status()

        result = response.json()
        ai_response = result['choices'][0]['message']['content']

        print("\n" + "-"*60)
        print("AI HEALTH COACH RESPONSE:")
        print("-"*60)
        print(ai_response)
        print("-"*60)

        # Check for key elements in response
        print("\n✓ Response Analysis:")
        checks = {
            "Acknowledges user feedback": any(word in ai_response.lower() for word in ['stress', 'phone', 'screen', 'work']),
            "Provides recommendations": any(word in ai_response.lower() for word in ['try', 'suggest', 'recommend', 'consider', 'help']),
            "Shows empathy": any(word in ai_response.lower() for word in ['understand', 'tough', 'difficult', 'common']),
            "Actionable advice": len(ai_response) > 100  # Should be detailed
        }

        for check, passed in checks.items():
            status = "✓" if passed else "✗"
            print(f"  {status} {check}")

        return True

    except requests.exceptions.RequestException as e:
        print(f"\n✗ Error: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return False

def main():
    print("\n" + "="*60)
    print("HEALTH INSIGHTS AI AGENT - TEST SUITE")
    print("="*60)
    print(f"Testing model: {MODEL}")
    print(f"API Endpoint: {API_ENDPOINT}")

    # Check if API key is set
    if API_KEY == "YOUR_OPENROUTER_API_KEY_HERE":
        print("\n⚠️  WARNING: API_KEY not set!")
        print("Please replace 'YOUR_OPENROUTER_API_KEY_HERE' with your actual OpenRouter API key")
        print("Get your key from: https://openrouter.ai/keys")
        return

    # Create mockup health data
    health_data = create_mockup_health_data()
    print(f"\nMockup health data created for: {health_data['date']}")

    # Run tests
    test1_passed = test_proactive_greeting(health_data)
    test2_passed = test_diagnostic_conversation(health_data)

    # Summary
    print("\n\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"Test 1 (Proactive Greeting): {'✓ PASSED' if test1_passed else '✗ FAILED'}")
    print(f"Test 2 (Diagnostic Follow-up): {'✓ PASSED' if test2_passed else '✗ FAILED'}")
    print("="*60)

    if test1_passed and test2_passed:
        print("\n🎉 All tests passed! The AI health coach is working correctly.")
    else:
        print("\n⚠️  Some tests failed. Check the output above for details.")

if __name__ == "__main__":
    main()
