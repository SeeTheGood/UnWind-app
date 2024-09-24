import Foundation

class Unwind1_5 {
    
    let apiKey = " "// Replace with your actual OpenAI API key
    let assistantId = "asst_2yAxYpU77d6m3pv0dBtxwKRW" // Replace with your Assistant ID
    
    // Function to send a message to the assistant
    func sendMessageToAssistant(message: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Step 1: Create a thread
        createThread { result in
            switch result {
            case .success(let threadId):
                // Step 2: Add the user message to the thread
                self.addMessageToThread(threadId: threadId, message: message) { addMessageResult in
                    switch addMessageResult {
                    case .success:
                        // Step 3: Run the assistant on the thread
                        self.runAssistantOnThread(threadId: threadId) { runResult in
                            switch runResult {
                            case .success(let responseMessage):
                                // Return the response message
                                completion(.success(["content": responseMessage]))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Create a Thread
    private func createThread(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/threads") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let threadId = json["id"] as? String {
                    completion(.success(threadId))
                } else {
                    // Log the raw response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw createThread response: \(responseString)")
                    }
                    completion(.failure(NSError(domain: "Parsing error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Add a Message to the Thread
    private func addMessageToThread(threadId: String, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let messageData: [String: Any] = [
            "role": "user",
            "content": message
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: messageData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
    
    // Run the Assistant on the Thread
    private func runAssistantOnThread(threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let runData: [String: Any] = [
            "assistant_id": assistantId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: runData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            // Log the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw runAssistantOnThread response: \(responseString)")
            }
            
            // Attempt to parse the response to get the run ID
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let runId = json["id"] as? String {
                    // Poll the run status until completion
                    self.pollRunStatus(threadId: threadId, runId: runId, completion: completion)
                } else {
                    completion(.failure(NSError(domain: "Parsing error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
    private func pollRunStatus(threadId: String, runId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            // Log the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw pollRunStatus response: \(responseString)")
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Look for the final event indicating the run is complete
                    if let event = json["event"] as? String, event == "thread.run.completed" {
                        // Assume the response content is in the 'data' field
                        if let data = json["data"] as? [String: Any] {
                            // Depending on how the data is structured, adjust the parsing logic
                            if let output = data["output"] as? String {
                                completion(.success(output))
                            } else {
                                completion(.failure(NSError(domain: "Parsing error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No output found in data"])))
                            }
                        } else {
                            completion(.failure(NSError(domain: "Parsing error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data field found in response"])))
                        }
                    } else {
                        // If still queued or running, wait and try again
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { // Polling interval
                            self.pollRunStatus(threadId: threadId, runId: runId, completion: completion)
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "Parsing error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response in polling"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
