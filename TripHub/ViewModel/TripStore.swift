//
//  TripDocuments.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 01/05/26.
//

import Foundation
import SwiftData

/* @Model: Menjadikan data Anda "abadi" (tersimpan di HP). */
@Model
class TripStore {
    var id : UUID
    var title : String
    var fileType : String
    var localPath : String
    var createdAt : Date
    
    /* NOTE : init (Initializer) adalah fungsi khusus yang dipanggil saat pertama kali Anda membuat objek tersebut. Ibaratnya, init adalah "resep" atau "syarat" untuk melahirkan sebuah data baru.
     */
    init(title : String, type : String, path : String ) {
        self.id = UUID()
        self.title = title
        self.fileType = type
        self.localPath = path
        self.createdAt = Date()
    }
    /*
     @Model: Menjadikan data Anda "abadi" (tersimpan di HP).

     var: Menjadikan data Anda "fleksibel" (bisa diedit).

     init: Menjadikan proses pembuatan data "jelas & otomatis".
     
     */
}
