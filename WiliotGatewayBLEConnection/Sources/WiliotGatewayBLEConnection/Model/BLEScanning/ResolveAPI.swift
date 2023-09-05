import Foundation

class ResolveAPI {
    public static var tagIDResolved: ((UnsafePointer<CChar>, Int) -> Void)?
    let host = "https://resolver.livingweb.app"
    let authorizationString = "Bearer 3|J8b7mUpgFVoYrTlGvKb4oo6Oogabl1mpFvU5Y367"
    
    struct ResolveResult: Codable {
        let timestamp: Int
        let externalId: String
        let ownerId: String?
        let labels: [String]?
    }

    struct ResolveResponse: Codable {
        let success: Bool
        let error: Bool
        let result: ResolveResult
    }
    
    // This function is mainly used for sending tag ID cStrings
    // from Swift to Unity. However, it can be sent to
    // any listener that is subsribed to the tagIDResolved delegate
    // Unity, in particular, has to receive cStrings instead of strings
    // There, it has to be converted to a C# string
    func publishResolvedTagId(message: String) {
        let cString = message.cString(using: .utf8)
        let length = message.count

        ResolveAPI.tagIDResolved?(cString!, length)
    }

    func extractExternalId(from jsonString: String) -> String?  {
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let response = try JSONDecoder().decode(ResolveResponse.self, from: jsonData)
                return response.result.externalId
            } catch {
                print(error)
            }
        }
        
        return nil
    }

    func createPayloadJSONString(payloadValue: String) -> String? {
        let payloadDictionary = ["payload": payloadValue]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payloadDictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print(error)
        }
        
        return nil
    }

    func sendPacketToResolveAPI(payloadString: String, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(host)/api/resolve/pixel") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payloadString.data(using: .utf8)
        // Configure request authentication
        request.setValue(
            authorizationString,
            forHTTPHeaderField: "Authorization"
        )
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    if let jsonString = String(data: data, encoding: .utf8),
                       let externalId = self.extractExternalId(from: jsonString) {
                        //print("json string from the server: \(jsonString)")
                        completion(externalId, nil)
                    } else {
                        completion(nil, nil)
                    }
                } catch {
                    completion(nil, error)
                }
            } else if let error = error {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}


