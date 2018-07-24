/*
    Copyright 2017, Kelvin Ma (“taylorswift”), kelvin13ma@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import XML

#if os(Linux)
    import Glibc

#elseif os(OSX)
    import Darwin

#else
    fatalError("Unsupported OS")

#endif

let DEFINITION_FILE_PATH:String = "sources/generator/gl.xml"

let LICENSE:String =
"""
/*
    THIS FILE IS GENERATED. ALL MODIFICATIONS MAY BE LOST!

    Copyright 2017, Kelvin Ma (“taylorswift”), kelvin13ma@gmail.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
"""

extension String
{
    init(_ buffer:[Unicode.Scalar])
    {
        self.init(buffer.map(Character.init))
    }

    var rstripped:String
    {
        var str:String = self
        while let c:Character = str.last
        {
            guard c == " " || c == "\n"
            else
            {
                break
            }

            str.removeLast()
        }

        return str
    }
}

enum Node:String, Equatable
{
    case extensions,
         `extension`,
         require,
         commands,
         command,
         feature,
         remove,
         groups,
         group,
         enums,
         `enum`,
         param,
         proto,
         ptype,
         name,

    // unused
         types,
         type,
         apientry,
         glx,
         vecequiv,
         alias,
         unused,
         comment
}

func ~=(_ a:[Node], _ b:[Node]) -> Bool
{
    return a == b
}

struct DefinitionParser:XMLParser
{
    private
    enum Version:CustomStringConvertible
    {
        case gl(Int, Int), gles(Int, Int)

        var description:String
        {
            switch self
            {
            case .gl(let v1, let v2):
                return "OpenGL \(v1).\(v2)"
            case .gles(let v1, let v2):
                return "OpenGL ES \(v1).\(v2)"
            }
        }

        static
        func == (_ a:Version, _ b:Version) -> Bool
        {
            switch a
            {
            case .gl(let v1, let v2):
                if case .gl(let u1, let u2) = b
                {
                    return v1 == u1 && v2 == u2
                }
                else
                {
                    return false
                }
            case .gles(let v1, let v2):
                if case .gles(let u1, let u2) = b
                {
                    return v1 == u1 && v2 == u2
                }
                else
                {
                    return false
                }
            }
        }
    }

    private
    enum Support:CustomStringConvertible
    {
        case added(Version), removed(Version), ext(String)

        var description:String
        {
            switch self
            {
            case .added(let version):
                return "Available since \(version)"
            case .removed(let version):
                return "Unavailable since \(version)"
            case .ext(let name):
                return "Available in extension '\(name)'"
            }
        }

        static
        func == (_ a:Support, _ b:Support) -> Bool
        {
            switch a
            {
            case .added(let version1):
                if case .added(let version2) = b
                {
                    return version1 == version2
                }
                else
                {
                    return false
                }

            case .removed(let version1):
                if case .removed(let version2) = b
                {
                    return version1 == version2
                }
                else
                {
                    return false
                }

            case .ext:
                if case .ext = b
                {
                    return true
                }
                else
                {
                    return false
                }
            }
        }
    }

    private
    enum GLType:String
    {
        case none = "",
             GLbitfield,
             GLboolean,
             GLbyte,
             GLchar,
             GLcharARB,
             GLclampd,
             GLclampf,
             GLclampx,
             GLDEBUGPROC,
             GLDEBUGPROCAMD,
             GLDEBUGPROCARB,
             GLDEBUGPROCKHR,
             GLdouble,
             GLeglImageOES,
             GLenum,
             GLfixed,
             GLfloat,
             GLhalfNV,
             GLhandleARB,
             GLint,
             GLint64,
             GLint64EXT,
             GLintptr,
             GLintptrARB,
             GLshort,
             GLsizei,
             GLsizeiptr,
             GLsizeiptrARB,
             GLsync,
             GLubyte,
             GLuint,
             GLuint64,
             GLuint64EXT,
             GLushort,
             GLvdpauSurfaceNV,
             GLvoid,
             struct__cl_context = "struct _cl_context",
             struct__cl_event   = "struct _cl_event",

             void                    = "void",
             unsafemutablerawpointer = "void *",
             unsafemutablepointer_u8 = "GLubyte *"

        var swiftType:String
        {
            switch self
            {
            case .GLboolean:
                return "OpenGL.Bool"
            case .GLdouble:
                return "OpenGL.Double"
            case .GLclampd:
                return "OpenGL.ClampDouble"
            case .GLfloat:
                return "OpenGL.Float"
            case .GLclampf:
                return "OpenGL.ClampFloat"
            case .GLbyte:
                return "OpenGL.Byte"
            case .GLchar:
                return "OpenGL.Char"
            case .GLcharARB:
                return "OpenGL.CharARB"
            case .GLshort:
                return "OpenGL.Short"
            case .GLint:
                return "OpenGL.Int"
            case .GLsizei:
                return "OpenGL.Size"
            case .GLenum:
                return "OpenGL.Enum"
            case .GLfixed:
                return "OpenGL.Fixed"
            case .GLclampx:
                return "OpenGL.ClampX"
            case .GLint64:
                return "OpenGL.Int64"
            case .GLint64EXT:
                return "OpenGL.Int64EXT"
            case .GLintptr:
                return "OpenGL.IntPointer"
            case .GLintptrARB:
                return "OpenGL.IntPointerARB"
            case .GLsizeiptr:
                return "OpenGL.SizePointer"
            case .GLsizeiptrARB:
                return "OpenGL.SizePointerARB"
            case .GLvdpauSurfaceNV:
                return "OpenGL.VdpauSurfaceNV"
            case .GLubyte:
                return "OpenGL.UByte"
            case .GLushort:
                return "OpenGL.UShort"
            case .GLhalfNV:
                return "OpenGL.HalfNV"
            case .GLuint:
                return "OpenGL.UInt"
            case .GLbitfield:
                return "OpenGL.Bitfield"
            case .GLuint64:
                return "OpenGL.UInt64"
            case .GLuint64EXT:
                return "OpenGL.UInt64EXT"

            case .GLDEBUGPROC:
                return "OpenGL.DebugProc"
            case .GLDEBUGPROCAMD:
                return "OpenGL.DebugProcAMD"
            case .GLDEBUGPROCARB:
                return "OpenGL.DebugProcARB"
            case .GLDEBUGPROCKHR:
                return "OpenGL.DebugProcKHR"

            case .GLhandleARB:
                return "OpenGL.HandleARB"
            case .GLeglImageOES:
                return "OpenGL.EGLImageOES"

            case .GLsync:
                return "OpenGL.Sync"

            case .struct__cl_context, .struct__cl_event:
                return "OpaquePointer?"
            case .unsafemutablerawpointer:
                return "UnsafeMutableRawPointer?"
            case .unsafemutablepointer_u8:
                return "UnsafeMutablePointer<UInt8>?"
            case .void, .GLvoid:
                return "()"

            case .none:
                fatalError("unreachable")
            }
        }
    }

    private
    enum PointerType:String
    {
        case none                      = "",
             mutable                   = "*",
             mutableRaw                = "void*",
             immutable                 = "const*",
             immutableRaw              = "constvoid*",

             mutableMutableRaw         = "void**",
             mutableImmutable          = "const**",
             mutableImmutableRaw       = "constvoid**",
             immutableImmutable        = "const*const*",
             immutableImmutableRaw     = "constvoid*const*",

             array2                    = "[2]"
    }

    private
    struct CurrentCommand
    {
        var name:String?            = nil,
            returnType:String       = "",
            parameters:[Parameter]  = []
    }

    private
    struct Command
    {
        let name:String,
            returnType:GLType,
            parameters:[Parameter]

        init(_ command:CurrentCommand)
        {
            guard let name:String = command.name
            else
            {
                fatalError("command '' has no name")
            }

            guard let returnType:GLType = GLType(rawValue: command.returnType)
            else
            {
                fatalError("command '\(name)' has an invalid return type '\(command.returnType)'")
            }

            self.name        = name
            self.returnType = returnType
            self.parameters  = command.parameters
        }
    }

    private
    struct CurrentParameter
    {
        var name   :String  = "",
            type   :String  = "",
            pointer:String  = "",
            group  :String? = nil,
            length :String? = nil
    }

    private
    struct Parameter
    {
        let name:String,
            type:GLType

        private
        let pointer:PointerType,
            group  :String?,
            length :String?

        var swiftType:String
        {
            switch self.pointer
            {
            case .none:
                return self.type.swiftType

            case .mutable:
                if self.type != .GLvoid
                {
                    return "UnsafeMutablePointer<\(self.type.swiftType)>?"
                }
                fallthrough

            case .mutableRaw:
                return "UnsafeMutableRawPointer?"

            case .immutable, .array2:
                return "UnsafePointer<\(self.type.swiftType)>?"

            case .immutableRaw:
                return "UnsafeRawPointer?"

            case .mutableMutableRaw:
                return "UnsafeMutablePointer<UnsafeMutableRawPointer?>?"

            case .mutableImmutable:
                return "UnsafeMutablePointer<UnsafeMutablePointer<\(self.type.swiftType)>?>?"

            case .mutableImmutableRaw:
                return "UnsafeMutablePointer<UnsafeRawPointer?>?"

            case .immutableImmutable:
                return "UnsafePointer<UnsafePointer<\(self.type.swiftType)>?>?"

            case .immutableImmutableRaw:
                return "UnsafePointer<UnsafeRawPointer?>?"
            }
        }

        init(_ parameter:CurrentParameter)
        {
            guard !parameter.name.isEmpty
            else
            {
                fatalError("command '' has no name")
            }

            guard let parameterType:GLType = GLType(rawValue: parameter.type)
            else
            {
                fatalError("parameter '\(parameter.name)' has an invalid type '\(parameter.type)'")
            }

            guard let pointerType:PointerType = PointerType(rawValue: parameter.pointer)
            else
            {
                fatalError("parameter '\(parameter.name)' has an invalid pointer type '\(parameter.pointer)'")
            }

            // fix parameter names that are Swift keywords
            if parameter.name == "func"
            {
                self.name = "f"
            }
            else if parameter.name == "in"
            {
                self.name = "input"
            }
            else
            {
                self.name    = parameter.name
            }
            self.type    = parameterType
            self.pointer = pointerType
            self.group   = parameter.group
            self.length  = parameter.length
        }
    }

    private
    var path:[Node] = [],

        constants:[(String, String, String)] = [ ],
        commands:[Command]                   = [ ],
        commandSupport:[String: [Support]]   = [:],

        //current_group:String           = "",
        //groups:[String: [String]]      = [:],

        currentConstantIsBitmask:Bool      = false,

        currentCommand:CurrentCommand?     = nil,
        currentParameter:CurrentParameter? = nil,
        currentVersion:Version?            = nil,
        currentExtension:Support?          = nil

    mutating
    func handle_data(data:[Unicode.Scalar])
    {
        let str:String = String(data)
        switch self.path
        {
        // it is important to note that return type declarations only ever have
        // “const” or “void” occur before the <ptype> element appears, if any.
        // the “const” can be ignored, and the “void” will never be followed by
        // any <ptype> element.
        case [Node.commands, Node.command, Node.proto]:
            self.currentCommand?.returnType += str.rstripped

        case [Node.commands, Node.command, Node.proto, Node.ptype]:
            self.currentCommand?.returnType = str

        case [.commands, .command, .proto, .name]:
            self.currentCommand?.name = str

        case [.commands, .command, .param]:
            self.currentParameter?.pointer += str.filter{ $0 != " " }

        case [.commands, .command, .param, .ptype]:
            self.currentParameter?.type = str

        case [.commands, .command, .param, .name]:
            self.currentParameter?.name = str

        default:
            break
        }
    }

    mutating
    func handle_tag_start(name:String, attributes:[String: String])
    {
        guard name != "registry"
        else
        {
            return
        }

        guard let nodeType:Node = Node(rawValue: name)
        else
        {
            print("unrecognized: \(name)")
            return
        }

        self.path.append(nodeType)

        switch self.path
        {
        case [.extensions, .extension]:
            var extn:String = attributes["name"]!
            if extn.starts(with: "GL_")
            {
                extn.removeFirst(3)
            }
            self.currentExtension = .ext(extn)

        case [.extensions, .extension, .require, .command]:
            let command:String = attributes["name"]!
            self.commandSupport[command, default: []].append(self.currentExtension!)

        case [.feature]:
            guard let versionStr:String    = attributes["number"],
                  let decimal:String.Index = versionStr.index(of: "."),
                  let v1:Int = Int(String(versionStr[..<decimal])),
                  let v2:Int = Int(String(versionStr[versionStr.index(after: decimal)...]))
            else
            {
                fatalError("invalid feature number")
            }

            switch attributes["api"]!
            {
            case "gl":
                self.currentVersion = .gl(v1, v2)
            case "gles1", "gles2":
                self.currentVersion = .gles(v1, v2)
            default:
                fatalError("invalid feature api")
            }

        case [.feature, .require, .command]:
            let command:String = attributes["name"]!
            guard let version:Version = self.currentVersion
            else
            {
                fatalError("unreachable")
            }

            if version == .gles(2, 0)
            {
                if let index:Int = self.commandSupport[command]?.index(where: { $0 == .added(.gles(1, 0)) })
                {
                    self.commandSupport[command]?[index] = .added(version)
                    break
                }
            }
            else if version == .gles(1, 0)
            {
                if self.commandSupport[command]?.contains(where: { $0 == .added(.gles(2, 0)) }) ?? false
                {
                    break
                }
            }

            self.commandSupport[command, default: []].append(.added(version))

        case [.feature, .remove, .command]:
            let command:String = attributes["name"]!
            self.commandSupport[command, default: []].append(.removed(self.currentVersion!))

        /*
        case [.groups, .group]:
            self.current_group = attributes["name"]!
            self.groups[self.current_group] = []

        case [.groups, .group, .enum]:
            self.groups[self.current_group]!.append(attributes["name"]!)
        */

        case [.enums]:
            self.currentConstantIsBitmask = attributes["type"] == "bitmask" ||
                // OcclusionQueryEventMaskAMD has buggy record
                attributes["namespace"] == "OcclusionQueryEventMaskAMD"

        case [.enums, .enum]:
            var name:String   = attributes["name"]!
            if let api:String = attributes["api"]
            {
                // GL_ACTIVE_PROGRAM_EXT has two different values
                name += "_" + api
            }

            if name.starts(with: "GL_") &&
            !("0" ... "9" ~= name.unicodeScalars[name.unicodeScalars.index(name.unicodeScalars.startIndex, offsetBy: 3)])
            {
                name.removeFirst(3)
            }

            let intType:String

            if attributes["type"] == "u"
            {
                intType = "UInt32"
            }
            else if attributes["type"] == "ull"
            {
                intType = "UInt64"
            }
            else
            {
                intType = self.currentConstantIsBitmask ? "UInt32" : "Int32"
            }

            self.constants.append((name, intType, attributes["value"]!))

        case [.commands, .command]:
            self.currentCommand = CurrentCommand()

        case [.commands, .command, .param]:
            self.currentParameter         = CurrentParameter()
            self.currentParameter?.length = attributes["len"]
            self.currentParameter?.group  = attributes["group"]

        default:
            break
        }
    }

    mutating
    func handle_tag_empty(name:String, attributes:[String: String])
    {
        self.handle_tag_start(name: name, attributes: attributes)
        self.handle_tag_end(name: name)
    }

    mutating
    func handle_tag_end(name:String)
    {
        guard name != "registry"
        else
        {
            return
        }

        switch self.path
        {
        case [.commands, .command]:
            guard let currentCommand = self.currentCommand
            else
            {
                fatalError("unreachable")
            }
            self.commands.append(Command(currentCommand))
            self.currentCommand = nil

        case [.commands, .command, .param]:
            guard let currentParameter = self.currentParameter
            else
            {
                fatalError("unreachable")
            }
            self.currentCommand?.parameters.append(Parameter(currentParameter))
            self.currentParameter = nil

        case [.feature]:
            self.currentVersion = nil

        case [.extensions, .extension]:
            self.currentExtension = nil

        default:
            break
        }

        guard let nodeType:Node = Node(rawValue: name)
        else
        {
            print("unrecognized: \(name)")
            return
        }

        guard self.path.removeLast() == nodeType
        else
        {
            fatalError("malformed XML, mismatched tag '\(name)'")
        }
    }

    mutating
    func handle_processing_instruction(target:String, data:[Unicode.Scalar]) { }

    mutating
    func handle_error(_ message:String, line:Int, column:Int)
    {
        fatalError("\(DEFINITION_FILE_PATH):\(line):\(column): \(message)")
    }


    func generateConstants(stream:UnsafeMutablePointer<FILE>)
    {
        fputs(LICENSE, stream)
        fputs("""
            
            extension OpenGL
            {
                // note: OpenGL.Int is Swift.Int32, not Swift.Int, and
                //       OpenGL.UInt is Swift.UInt32, not Swift.UInt
                typealias Bool           = Swift.Bool
                typealias Double         = Swift.Double
                typealias ClampDouble    = Swift.Double
                typealias Float          = Swift.Float
                typealias ClampFloat     = Swift.Float
                typealias Byte           = Swift.Int8
                typealias Char           = Swift.Int8
                typealias CharARB        = Swift.Int8
                typealias Short          = Swift.Int16
                typealias Int            = Swift.Int32
                typealias Size           = Swift.Int32
                typealias Enum           = Swift.Int32
                typealias Fixed          = Swift.Int32
                typealias ClampX         = Swift.Int32
                typealias Int64          = Swift.Int64
                typealias Int64EXT       = Swift.Int64
                typealias IntPointer     = Swift.Int
                typealias IntPointerARB  = Swift.Int
                typealias SizePointer    = Swift.Int
                typealias SizePointerARB = Swift.Int
                typealias VdpauSurfaceNV = Swift.Int
                typealias UByte          = Swift.UInt8
                typealias UShort         = Swift.UInt16
                typealias HalfNV         = Swift.UInt16
                typealias UInt           = Swift.UInt32
                typealias Bitfield       = Swift.UInt32
                typealias UInt64         = Swift.UInt64
                typealias UInt64EXT      = Swift.UInt64
                typealias HandleARB      = UnsafeMutableRawPointer?
                typealias EGLImageOES    = UnsafeMutableRawPointer?
                typealias Sync           = OpaquePointer?

                typealias DebugProc = @convention(c)
                    (Swift.Int32, Swift.Int32, Swift.UInt32, Swift.Int32, Swift.Int32, UnsafePointer<Swift.Int8>?, UnsafeRawPointer?) -> ()
                typealias DebugProcARB = DebugProc
                typealias DebugProcKHR = DebugProc

                typealias DebugProcAMD = @convention(c)
                    (Swift.Int32, Swift.Int32, Swift.Int32, Swift.Int32, UnsafePointer<Swift.Int8>?, UnsafeMutableRawPointer?) -> ()


            """, stream)

        var first:Bool = true
        for (name, intType, value):(String, String, String) in self.constants
        {
            if first
            {
                fputs("    static \n    let ", stream)
                first = false
            }
            else
            {
                fputs(", \n        ", stream)
            }

            fputs("\(name):Swift.\(intType) = \(value)", stream)
        }
        fputs("\n}\n", stream)
    }

    func generateLoader(stream:UnsafeMutablePointer<FILE>)
    {
        fputs(LICENSE, stream)
        fputs("""
            
            extension OpenGL
            {
            """, stream)

        let supportStrings:[String]     = Set<String>(self.commandSupport.values.lazy.flatMap{ $0 }.map{ $0.description }).sorted()
        let stringIndices:[String: Int] = .init(uniqueKeysWithValues: supportStrings.lazy.enumerated().map{ ($0.1, $0.0) })

        var first:Bool = true
        for (i, support_str):(Int, String) in supportStrings.enumerated()
        {
            if first
            {
                fputs("""
                    
                    fileprivate static 
                    let 
                    """, stream)
                first = false
            }
            else
            {
                fputs(", \n    ", stream)
            }

            fputs("ss\(i):String = \"\(support_str)\"", stream)
        }
        fputs("""


                // OpenGL function loaders; functions are loaded lazily and replace
                // themselves with their loaded versions on first call

                """, stream)

        var loaders:[String] = []
        for command in self.commands
        {
            let arguments:String      = command.parameters.map{ $0.name }.joined(separator: ", "),
                types:String          = command.parameters.map{ $0.swiftType }.joined(separator: ", "),
                parameterList:String  = command.parameters.map{ "\($0.name):\($0.swiftType)" }.joined(separator: ", "),

                ret:String            = (command.returnType != .void && command.returnType != .GLvoid) ?
                                            " -> \(command.returnType.swiftType)" : "",
                support:String        = self.commandSupport[command.name]!
                                            .map{ "OpenGL.ss\(stringIndices[$0.description]!)" }
                                            .joined(separator: ", ")

            fputs("""
            static 
            var \(command.name):@convention(c) (\(types)) -> \(command.returnType.swiftType) = _load_\(command.name)
            
            """, stream)
            
            loaders.append("""
            fileprivate 
            func _load_\(command.name)(\(parameterList))\(ret)
            {
                OpenGL.\(command.name) = unsafeBitCast(OpenGL.getfp(\"\(command.name)\", support: [\(support)]), to: Swift.type(of: OpenGL.\(command.name)))
                \(ret.isEmpty ? "" : "return ")OpenGL.\(command.name)(\(arguments))
            }
            
            """)
        }
        
        fputs("""

            }
            
            """, stream)
        
        for loader:String in loaders 
        {
            fputs(loader, stream)
        }
    }
}

var parser:DefinitionParser = DefinitionParser()
parser.parse(path: DEFINITION_FILE_PATH)

// write constants file
guard let stream_constants:UnsafeMutablePointer<FILE> = fopen("sources/polysphere/gl/bindings/_constants.swift", "w")
else
{
    fatalError("failed to open stream")
}
parser.generateConstants(stream: stream_constants)

// write loader file
guard let stream_loader:UnsafeMutablePointer<FILE> = fopen("sources/polysphere/gl/bindings/_loader.swift", "w")
else
{
    fatalError("failed to open stream")
}
parser.generateLoader(stream: stream_loader)
