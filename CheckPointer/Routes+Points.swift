//
//  Routes+Points.swift
//  CheckPointer
//
//  Created by Mike on 20/08/2020.
//  Copyright © 2020 mannett. All rights reserved.
//

import Foundation
class Point {
    let name: String
    let long: Double
    let lat: Double
    
    init(name: String, lat: Double, long: Double) {
        self.name  = name
        self.long = long
        self.lat  = lat
    }
    
}

class Route {
    let name: String
    var points: [Point] = []
    var pointIndex: Int = Int.min
    
    init(name: String) {
        self.name  = name
    }
    
    func addPoint(point: Point) {
        points.append(point)
    }
    
    func addPoint(name: String, lat: Double, long: Double) {
        let point=Point(name:name, lat:lat, long:long )
        addPoint(point:point)
    }
    
    func prevPoint() -> Point {
        if self.pointIndex == Int.min {self.pointIndex=0}
        else {
            self.pointIndex -= 1
            if self.pointIndex < 0 { self.pointIndex = self.points.count-1 }
        }
        return self.points[pointIndex]
    }
    
    func nextPoint() -> Point {
        if self.pointIndex == Int.min {self.pointIndex=0}
        else {
            self.pointIndex += 1
            if self.pointIndex >= self.points.count { self.pointIndex = 0 }
        }
        
        return self.points[self.pointIndex]
    }
    
    func currentPoint() -> Point {
        if self.pointIndex == Int.min {self.pointIndex=0}
        
        return self.points[self.pointIndex]
    }
}

var routes: [Route] = []
var currentRoute: Route? = nil
var routeIndex: Int = Int.min
var prevRoute: Route {
    get {
        if routeIndex == Int.min {routeIndex=0}
        else {
            routeIndex -= 1
            if routeIndex < 0 { routeIndex = routes.count-1 }
        }
        return routes[routeIndex]
    }
}

var nextRoute: Route {
    get {
        if routeIndex == Int.min {routeIndex=0}
        else {
            routeIndex += 1
            if routeIndex >= routes.count { routeIndex = 0 }
        }
        
        return routes[routeIndex]
    }
}

var currRoute: Route {
    get {
        if routeIndex == Int.min {routeIndex=0}
        
        return routes[routeIndex]
    }
}

// Manage Events data and unpacking to Routes Structure
class JSONEvents {
    struct Event: Decodable {
        enum Category: String, Decodable {
            case swift, combine, debugging, xcode
        }
        
        let name: String
        let activities: [Int]
        let comment: String?
        let start: [Double]?
        let end: [Double]?
        let cps: [[Double]]?
        let checkpointer : Bool?
    }
    
    struct Events: Decodable {
        enum Category: String, Decodable {
            case swift, combine, debugging, xcode
        }
        let comment: String?
        let usage: String?
        let events: [Event]
    }
    
    // Default location if we have no routes data.
    let winHill = """
            {
                "events" : [
                {"name":"Win Hill", "cps":[[53.362418, -1.720909]],
                    "activities":[]}
                ]
            }
            """.data(using: .utf8)!
    
    // Parse Events JSON creating a new routes structure
    func parseJSONEvents(data: Data) -> [Route] {
        var newRoutes: [Route] = []
        if let events = try? JSONDecoder().decode(Events.self, from: data) {
            for event in events.events {
                if event.cps?.count ?? 0 > 0 && event.checkpointer ?? true {
                    let route=Route(name:event.name)
                    print(event.name)
                    if let start=event.start { route.addPoint(name: "Start", lat:start[0], long:start[1]) }
                    for i in 0...event.cps!.count-1
                    {
                        let name="CP"+String(i+1)
                        let cp=event.cps![i]
                        route.addPoint(name: name, lat:cp[0], long:cp[1])
                    }
                    newRoutes.append(route)
                }
            }
        }
        
        return newRoutes
    }
    
    enum Error: Swift.Error {
        case fileAlreadyExists
        case invalidDirectory
        case writtingFailed
    }
    
    let savefileURL=FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("events.json")
    
    // Save JSON routes to cache
    func saveJSONEvents(data: Data) -> Bool {
        do
        {
            try data.write(to: savefileURL)
        } catch {
            print("saveJSONEvents Unexpected error: \(error).")
            return false
        }
        
        return true
    }
    
    // Load JSON routes from cache.
    func loadJSONEvents() -> Data? {
        var data:Data
        do
        {
            try data = Data(contentsOf: savefileURL)
        } catch {
            print("loadJSONEvents Unexpected error: \(error).")
            return nil
        }
        
        return data
    }
    
    // Parse JSON for routes if this looks good cache a copy and update routes
    @discardableResult func newRoute(data: Data) -> Bool  {
        let newRoutes = parseJSONEvents(data: data)
        var ok = newRoutes.count > 0
        
        if ok { ok = saveJSONEvents( data:data ) }
        if ok {routes=newRoutes}
        
        return ok
    }
    
    // Load an initial set of routes preferably from that cache and failing that add a default route
    func setupRoutes() {
        print("JSONEvents.setupRoutes")
        
        if let data=loadJSONEvents() {
            let newRoutes = parseJSONEvents(data: data)
            let ok = newRoutes.count > 0
            if ok {routes=newRoutes}
            return
        }
        
        print("JSONEvents.setupRoutes - setting up default Win Hill")
        newRoute(data: winHill)
    }
}

// Some test routes data.
func setupJSONTestRoutes() {
    let json = """
            {
                "events" : [
                {"name":"SS Gusset", "start":[53.401013, -1.743078],"cps":[[53.404458, -1.730162],[53.399837, -1.707014],[53.411032, -1.719167]],
                    "activities":[], "comment" : ""},
                
                {"name":"SS Pike v2", "start":[53.486198, -1.660310],"cps":[[53.472638, -1.686522]],
                    "activities":[], "comment" : ""},

                {"name":"SS Rimmer", "start":[53.382774, -1.680731],"cps":[[53.386180, -1.697900],[53.399837, -1.707014],[53.393973, -1.708566],[53.388636, -1.696097],[53.375087, -1.698313]],
                    "activities":[], "comment" : ""}

                ]
            }
            """.data(using: .utf8)!
    JSONEvents().newRoute(data:json)
}



extension ViewController{
    // setup routes initially using (cached) local data and then initiate request from webservice
    func setupRoutes() {
        JSONEvents().setupRoutes()
        // setupJSONTestRoutes()
        fetchEvents(completionHandler: JSONEvents().newRoute)
    }
}


func fetchEvents( completionHandler: @escaping (Data) -> Bool ) {
    let url = URL(string: "https://ttviewer.serverless.social/events")!
    
    let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
        if let error = error {
            print("Error with fetching events: \(error)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
                print("Error with the response, unexpected status code: \(String(describing: response))")
                return
        }
        
        //if let data = data,
        //     JSONEvents.parseJSONEvents(data:data)
        
        if let data = data {
            _ = completionHandler(data)
        }
    })
    task.resume()
}

