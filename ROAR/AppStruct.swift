//
//  AppStruct.swift
//  ROAR
//
//  Created by Michael Wu on 9/11/21.
//

import Foundation
struct AppInfo : Codable {
    static var sessionData: SessionData = SessionData()
    static var curr_world_name: String = "berkeley"
    static var bluetootConfigurations: BluetoothConfigurations? = nil
    static var pc_address: String = "10.0.0.2"
    static var udp_world_cam_port: Int32 = 8001
    static var udp_depth_cam_port: Int32 = 8002
    static var udp_veh_state_port: Int32 = 8003
    static var udp_control_port: Int32 = 8004
    static func get_ar_experience_name(name: String=AppInfo.curr_world_name) -> String{
        return "\(name)_ar_experience_data"
    }
    
    static func save() {
        UserDefaults.standard.setValue([
                                        "bluetooth_name": AppInfo.bluetootConfigurations?.name ?? "",
                                        "bluetooth_uuid": AppInfo.bluetootConfigurations?.uuid?.uuidString ?? ""],
                                       forKey: "bluetooth_data")
        
        UserDefaults.standard.setValue(AppInfo.pc_address, forKey: "pc_address")
    }
    static func load() {
        if UserDefaults.standard.value(forKey: "bluetooth_data") != nil {
            let data =  UserDefaults.standard.value(forKey: "bluetooth_data") as! Dictionary<String, String>
            AppInfo.bluetootConfigurations = BluetoothConfigurations(name: data["bluetooth_name"], uuid: UUID(uuidString: data["bluetooth_uuid"]!))            
        }
        if UserDefaults.standard.value(forKey: "pc_address") != nil {
            let data = UserDefaults.standard.value(forKey: "pc_address") as! String
            AppInfo.pc_address = data
        }
    }
}
struct SessionData: Codable {
    /*
     Instance data. Do NOT cache or save this data. When user start the app again, this data will start from default.
     */
    var shouldCaliberate: Bool = true
    var isTracking:Bool = false
    var isCaliberated:Bool = false
    var isBLEConnected:Bool = false
    var shouldAutoDrive: Bool = false
}


struct BluetoothConfigurations: Codable {
    var name: String?;
    var uuid: UUID?;
    
    
    func describe() -> String {
        return """
                name: \(String(describing: AppInfo.bluetootConfigurations?.name))
                uuid: \(String(describing: AppInfo.bluetootConfigurations?.uuid))
                """
    }
    
}
