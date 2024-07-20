import Foundation

struct QRCodeParsedResult {
    var rawString: String
    var type: QRCodeResultType
    var parsedData: [String: String]
}

final class QRCodeParser {
    private init() { }
    
    static func parseQRCode(_ qrString: String) -> QRCodeParsedResult {
        var resultType: QRCodeResultType = .unknown
        var parsedData: [String: String] = [:]
        
        // Identify type
        if qrString.starts(with: "http://") || qrString.starts(with: "https://") {
            resultType = .url
            parsedData["URL"] = qrString
        } else if qrString.starts(with: "MATMSG:") {
            resultType = .email
            parsedData = parseEmail(qrString)
        } else if qrString.contains("BEGIN:VCARD") {
            resultType = .contact
            parsedData = parseVCard(qrString)
        } else if qrString.starts(with: "MECARD:") {
            resultType = .contact
            parsedData = parseMeCard(qrString)
        } else if qrString.starts(with: "SMSTO:") {
            resultType = .message
            parsedData = parseMessage(qrString)
        } else if qrString.starts(with: "WIFI:") {
            resultType = .wifi
            parsedData = parseWiFi(qrString)
        } else if qrString.starts(with: "geo:") {
            resultType = .location
            parsedData = parseLocation(qrString)
        } else if qrString.starts(with: "BARCODE:") {
            resultType = .barcode
            parsedData["Text"] = qrString.replacingOccurrences(of: "BARCODE:", with: "")
        } else {
            resultType = .text
            parsedData["Text"] = qrString
        }
        
        return QRCodeParsedResult(rawString: qrString, type: resultType, parsedData: parsedData)
    }
    
    private static func parseEmail(_ qrString: String) -> [String: String] {
        var emailData: [String: String] = [:]
        
        let components = qrString.replacingOccurrences(of: "MATMSG:", with: "").components(separatedBy: ";")
        for component in components {
            var keyValue = component.components(separatedBy: ":")
            if keyValue.count > 2 {
                keyValue[1] += keyValue[2...keyValue.count - 1].joined()
                keyValue = Array(keyValue[0...1])
            }
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                switch key {
                case "TO":
                    emailData["Mail"] = value
                case "SUB":
                    emailData["Subject"] = value
                case "BODY":
                    emailData["Message"] = value
                default:
                    break
                }
            }
        }
        
        return emailData
    }
    
    private static func parseVCard(_ qrString: String) -> [String: String] {
        var vCardData: [String: String] = [:]
        
        let lines = qrString.components(separatedBy: "\n")
        for line in lines {
            let keyValue = line.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if key == "FN" || key == "N" {
                    vCardData["Contact Name"] = value
                } else if key == "TEL" || key.contains("TEL") {
                    vCardData["Phone Number"] = value
                } else if key == "EMAIL" || key.contains("EMAIL") {
                    vCardData["Mail"] = value
                } else if key == "URL" {
                    vCardData["URL"] = value
                }
            }
        }
        
        return vCardData
    }
    
    private static func parseMeCard(_ qrString: String) -> [String: String] {
        var meCardData: [String: String] = [:]
        
        let components = qrString.replacingOccurrences(of: "MECARD:", with: "").components(separatedBy: ";")
        for component in components {
            var keyValue = component.components(separatedBy: ":")
            if keyValue.count > 2 {
                keyValue[1] += keyValue[2...keyValue.count - 1].joined()
                keyValue = Array(keyValue[0...1])
            }
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                switch key {
                case "N":
                    meCardData["Contact Name"] = value
                case "TEL":
                    meCardData["Phone Number"] = value
                case "EMAIL":
                    meCardData["Mail"] = value
                case "URL":
                    meCardData["URL"] = value
                default:
                    break
                }
            }
        }
        
        return meCardData
    }
    
    private static func parseMessage(_ qrString: String) -> [String: String] {
        var messageData: [String: String] = [:]
        
        let components = qrString.replacingOccurrences(of: "SMSTO:", with: "").components(separatedBy: ":")
        if components.count == 2 {
            messageData["Phone Number"] = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            messageData["Message"] = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return messageData
    }
    
    private static func parseWiFi(_ qrString: String) -> [String: String] {
        var wifiData: [String: String] = [:]
        
        let components = qrString.replacingOccurrences(of: "WIFI:", with: "").components(separatedBy: ";")
        for component in components {
            let keyValue = component.components(separatedBy: ":")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)
                switch key {
                case "S":
                    wifiData["WiFi Name"] = value
                case "P":
                    wifiData["Password"] = value
                case "T":
                    wifiData["Type"] = value
                default:
                    break
                }
            }
        }
        
        return wifiData
    }

    private static func parseLocation(_ qrString: String) -> [String: String] {
        var locationData: [String: String] = [:]
        
        let components = qrString.replacingOccurrences(of: "geo:", with: "").components(separatedBy: ",")
        if components.count == 2 {
            locationData["Location"] = "\(components[0].trimmingCharacters(in: .whitespacesAndNewlines)), \(components[1].trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        
        return locationData
    }
}
