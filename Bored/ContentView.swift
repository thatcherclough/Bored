//
//  ContentView.swift
//  Bored
//
//  Created by Thatcher Clough on 5/28/21.
//

import SwiftUI

struct ContentView: View {
    private var prompt: String = "You're bored?"
    public static var transitionDuration: Double = 0.35
    
    @State private var company = "Alone"
    @State var showPrompt: Bool = false
    @State var showOptions: Bool = false
    @State private var showActivity: Bool = false
    @State private var activitySet: Bool = false
    @State private var previousActivity: String = ""
    @State private var activity = "Go fix this code" {
        didSet {
            if activity == previousActivity && activity != "Go connect to the internet" && !activity.contains("fix this code") {
                setActivity()
            } else {
                activitySet = true
                previousActivity = activity
            }
        }
    }
    @State private var link: String = "https://github.com/thatcherclough/Bored"
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack {
            Spacer()
            
            if showPrompt {
                Text(prompt)
                    .font(.system(size: 35, weight: .bold))
                    .transition(AnyTransition.scale.animation(Animation.spring(response: ContentView.transitionDuration, dampingFraction: 0.6, blendDuration: 1)))
                    .onAppear() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + ContentView.transitionDuration + 1) {
                            showOptions = true
                        }
                    }
                
                Spacer()
            }
            
            if showOptions {
                VStack {
                    Button {
                        displayActivity()
                    } label: {
                        Text("Click me!")
                    }
                    .buttonStyle(ClickMeButtonStyle())
                    
                    Picker(selection: $company, label: Text("")){
                        ForEach(["Alone", "With others"], id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .transition(.asymmetric(insertion: AnyTransition.scale.animation(Animation.spring(response: ContentView.transitionDuration, dampingFraction: 0.6, blendDuration: 1)), removal: AnyTransition.scale.animation(Animation.spring(response: ContentView.transitionDuration / 2, dampingFraction: 1, blendDuration: 1))))
                
                Spacer()
                Spacer()
            } else if showActivity {
                VStack {
                    VStack {
                        Text(activity)
                            .font(.system(size: 30, weight: .semibold))
                            .frame(minWidth: 200, idealWidth: 225, maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        
                        if !link.isEmpty {
                            Button {
                                openURL(URL(string: link)!)
                            } label: {
                                Text(link)
                                    .font(.system(size: 13))
                                    .frame(minWidth: 150, idealWidth: 175, maxWidth: 200)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                    }
                    .padding(.bottom)
                    
                    Button {
                        displayActivity()
                    } label: {
                        Text("Still bored?")
                    }
                    .buttonStyle(StillBoredButtonStyle())
                }
                .transition(.asymmetric(insertion: AnyTransition.scale.animation(Animation.spring(response: ContentView.transitionDuration, dampingFraction: 0.6, blendDuration: 1)), removal: AnyTransition.scale.animation(Animation.spring(response: ContentView.transitionDuration / 2, dampingFraction: 1, blendDuration: 1))))
                
                Spacer()
                Spacer()
            }
        }
        .animation(.spring(response: ContentView.transitionDuration, dampingFraction: 0.6, blendDuration: 1))
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showPrompt = true
            }
        }
    }
    
    func displayActivity() {
        DispatchQueue.main.asyncAfter(deadline: .now() + ContentView.transitionDuration / 2) {
            showOptions = false
            showActivity = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + ContentView.transitionDuration) {
                setActivity()
                setShowActivity()
            }
        }
    }
    
    func setShowActivity() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if activitySet {
                showActivity = true
            } else {
                setShowActivity()
            }
        }
    }
    
    func setActivity() {
        activitySet = false
        let alone = company == "Alone"
        
        getBoredAPIResponse(alone: alone) { (response) in
            if response == nil {
                activity = "Go fix this code (An error occurred)"
                link = "https://github.com/thatcherclough/Bored"
            } else {
                let json = response!
                if let errorDesciption = json["error"] as? String {
                    if errorDesciption == "The Internet connection appears to be offline." {
                        activity = "Go connect to the internet"
                        link = ""
                    } else {
                        activity = "Go fix this code (Error: \(errorDesciption))"
                        link = "https://github.com/thatcherclough/Bored"
                    }
                } else if let activity = json["activity"] as? String {
                    if let participants = json["participants"] as? Int {
                        if !alone && participants == 1 {
                            setActivity()
                        } else {
                            if let link = json["link"] as? String {
                                self.link = link
                            }
                            self.activity = activity
                        }
                    } else {
                        self.activity = "Go fix this code (Error: Could not get participants)"
                        link = "https://github.com/thatcherclough/Bored"
                    }
                } else {
                    activity = "Go fix this code (Error: Could not get activity)"
                    link = "https://github.com/thatcherclough/Bored"
                }
            }
        }
    }
    
    func getBoredAPIResponse(alone: Bool, completion: @escaping ([String: Any]?) -> Void) {
        let urlStub = "https://www.boredapi.com/api/activity"
        guard let url = URL(string: alone ? urlStub + "?participants=1" : urlStub) else {
            return completion(["error": "Invalid URL"])
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                return completion(["error": error?.localizedDescription ?? "An error occurred"])
            }
            guard let data = data else {
                return completion(nil)
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    return completion(json)
                } else {
                    return completion(nil)
                }
            } catch {
                return completion(nil)
            }
        }
        .resume()
    }
}

struct ClickMeButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 280, height: 50)
            .background(Color("Deep purple"))
            .foregroundColor(Color.white)
            .cornerRadius(25)
            .animation(.spring(response: ContentView.transitionDuration, dampingFraction: 0.35, blendDuration: 1))
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .shadow(color: Color("Deep purple").opacity(0.3), radius: 10)
    }
}

struct StillBoredButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 150, height: 50)
            .background(Color("Deep purple"))
            .foregroundColor(Color.white)
            .cornerRadius(25)
            .animation(.spring(response: ContentView.transitionDuration, dampingFraction: 0.35, blendDuration: 1))
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .shadow(color: Color("Deep purple").opacity(0.3), radius: 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
