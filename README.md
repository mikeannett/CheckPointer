# CheckPointer
IOS App to show bearing and distance to check points

## Project Status
This app doesn't currently work well enough to be of interest... watch this space.
Project Status: First version checked in, but not had chance to verify if it can be cloned and built successfully.
Current dev environment: MacOs 10.13.6, Swift 4.2, Xcode 10

## Checkpoint data
Project depends on events.json structure which is currently served from a hosted version of this project; https://github.com/mikeannett/time-trial-viewer-server

Although you could relatively easily hard code or redirect this to your own events.json structure in Routes+Points.swift.

```
 { 
    "events" : [
      {"name":"test", "start":[53.409784, -1.666004],"cps":[[53.415379, -1.704147],[53.409886, -1.716855],[53.407740, -1.702285]],
        "checkpointer" : true,
        "activities":[] }
    ]
 }
```
