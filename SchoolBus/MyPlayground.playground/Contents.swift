//: Playground - noun: a place where people can play

import UIKit
import AblyRealtime

var str = "Hello, playground"
debugPrint(str)

var client: ARTRealtime!

client = ARTRealtime(key: "QGOsVA.UnM4VQ:YuOO9DIWTgs2BcPZ")

let channel = client.channels.get("Position")

channel.subscribe("Position"){ message in debugPrint(message.data) }


channel.publish("hello", data: "world")

client.channels.exists("Position")



var state: ARTRealtimeChannelState!

state = client.channels.get("Position").state






