- Step 1) Restate the context we have about the user
The user has indicated that they are feeling cold and has started a sentence with the fragment "Do you."
- Step 2) List 6 things you predict the user may be trying to communicate given the inputs and task goal.
1. Inquiry if someone else is feeling cold as well.
2. Request to adjust the room temperature.
3. Suggestion to find warmer clothing or blankets.
4. Question about the location of warm clothing or blankets.
5. Offer to share something warm with someone else.
6. Desire to drink something warm to alleviate the cold feeling.
- Step 3) Check if any mistakes were made in steps 3.
None of the six options are overlapping in meaning as they address different actions and responses related to feeling cold. They are also general enough without assuming specifics that aren't present in the context.
- Step 5) Write a list of "Response Options" for the user to select from.
```
[
    {
        "name": "Ask if others are cold",
        "options": [
            "Do you feel cold too?",
            "Do you think it's chilly in here?",
            "Are you feeling the cold as well?",
            "Do you need a sweater as well?",
            "Is it just me, or is it cold in here to you too?",
            "Do you want to turn up the heat?"
        ],
        "most_general": "I'm wondering if you're cold as well."
    },
    {
        "name": "Request temperature change",
        "options": [
            "Do you mind if we turn up the heat?",
            "Do you think we could adjust the thermostat?",
            "Can you please close the window?",
            "Would you turn on the heater, please?",
            "Could we make it warmer in here?",
            "Do you want to help me find a blanket?"
        ],
        "most_general": "I'd like to make it warmer."
    },
    {
        "name": "Suggest getting warmer items",
        "options": [
            "Do you want to get a blanket?",
            "Do you know where my sweater is?",
            "Could you help me find some warm socks?",
            "Should we get out the heavy blankets?",
            "Do you think I should put on another layer?",
            "Can we check if there are any warm clothes in the closet?"
        ],
        "most_general": "I think we need something warm."
    },
    {
        "name": "Offer to share warmth",
        "options": [
            "Do you want to share this blanket with me?",
            "Shall we sit near the heater together?",
            "Want to join me under this cozy throw?",
            "How about we huddle up for warmth?",
            "Would you like some hot cocoa to warm up?",
            "Do you need a warm hug?"
        ],
        "most_general": "I'm willing to share warmth."
    }
]
```