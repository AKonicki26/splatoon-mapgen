#imports, all of these are from standard library
import os, json, strutils, tables, sequtils, random

# Needs to be called before any random calls, seeds the random number generator
randomize()

# let acts like a constant
let Mappool_Directory: string = "./Mappools/"

proc exitProcess(exitCode: int) = 
    let _ = readLine(stdin)
    quit(exitCode)

if (not dirExists(Mappool_Directory)):
    echo "Map Pool directory not found, creating..."
    createDir(Mappool_Directory)
    echo "Map pool directory created. Please go fill it"
    exitProcess(1)
    

# Define data structures
# Note how we only enter the "type" keyword once
type
    # similar to C++ typedef, create a new type that aliase as another existing type
    Map = string
    Mode = string

    MapPool = object
        tw: seq[string]
        sz: seq[string]
        tc: seq[string]
        rm: seq[string]
        cb: seq[string]

    Game = object
        map: string
        mode: string

    Match = object
    # keyword overriding, we can use the word 'type' as a variable name
    # even though its a keyword by surrounding it with `` characters
        `type`: string
        games: seq[Game]

    MapList = object
        matches: seq[Match]

# Function definitions

# proc to declare a standard function
proc printMappools(poolFiles: seq[string]): void =
    echo "Select a map pool file: "
    for index, file in poolFiles:
        echo index + 1, " - ", file

# Forward declaration of function to allow it to be used in getMapPoolFiles
proc getFileExtension(self: string): string

proc getMapPoolFiles(): seq[string] =
    for file in walkDir(Mappool_Directory):
        if file.kind == pcFile and file.path.getFileExtension() == ".json":
            # result is a keyword for the return value
            result.add(file.path)

# extension function by declaing a variable with the name "self"
proc getFileExtension(self: string): string =
    result = self.splitFile().ext

# Operator overloading
proc `+=`(source: var Match, gameToAdd: Game) =
    source.games &= gameToAdd

proc `+=`(source: var MapList, matchToAdd: Match) =
    source.matches &= matchToAdd

# Type classes: ++ operator overload will work on any numerical variabele
proc `++`(source: var SomeOrdinal) =
    source += 1

var mapPlayCounts = initTable[Map, int8]()

var mapPool: MapPool

proc getMapsWithMinimalPlays(mode: Mode): seq[Map] = 
    let mapsOfMode: seq[Map] = case string(mode):
    of "tw":
        mapPool.tw.mapIt(Map(it))
    of "sz":
        mapPool.sz.mapIt(Map(it))
    of "tc":
        mapPool.tc.mapIt(Map(it))
    of "rm":
        mapPool.rm.mapIt(Map(it))
    of "cb":
        mapPool.cb.mapIt(Map(it))
    else:
        mapPool.sz.mapIt(Map(it))

    echo "Here"

    #let mapsOfMode: seq[Map] = gameCounts.pairs.toSeq.filterIt(it[0].mode == string(mode)).toSeq
    let validMapPlays = mapPlayCounts.pairs.toSeq.filterIt(mapsOfMode.contains(it[0])).toTable()

    result = validMapPlays.pairs.toSeq.filterIt(it[1] == min(validMapPlays.values.toSeq)).mapIt(it[0]).toSeq
        
let mapPoolFiles = getMapPoolFiles()

if (mapPoolFiles.len == 0):
    echo "No files found, please get some files ready!!"
    exitProcess(1)

printMappools(mapPoolFiles)

var rawInput = readLine(stdin)
let selectedIndex = parseInt(rawInput)

var mapPoolFile: string

try:
    mapPoolFile = mapPoolFiles[selectedIndex - 1]
except Exception:
    echo "Invalid selection. Exiting."
    exitProcess(1)

# uses nim's "to" macro to automatically deeserialize the json into a custom defined object
mapPool = parseFile(mapPoolFile)["mapPool"].to(MapPool)

echo "Please enter the number of matches to play"
rawInput = readLine(stdin)
let matchCount = parseInt(rawInput)

echo "Please enter the number of games in each match"
rawInput = readLine(stdin)
let gameCountPerMatch = parseInt(rawInput)

echo "Please enter the type of match to play (Play all, Best of)"
let matchType = readLine(stdin)

# Prepare table for all games
for map in mapPool.tw:
    mapPlayCounts.add(Map(map), 0)

for map in mapPool.sz:
    mapPlayCounts[map] = 0

for map in mapPool.tc:
    mapPlayCounts[map] = 0

for map in mapPool.rm:
    mapPlayCounts[map] = 0

for map in mapPool.cb:
    mapPlayCounts[map] = 0

var mapList: MapList
var gameCount: int

for matchIndex in 0..(matchCount - 1):

    var currentMatch = Match(`type`: matchType)

    let matchNumber = matchIndex + 1
    # Maplist assumes starting with Zones and rotating evenly

    proc getMode(gameCount: int): string = 
        let cycleCount = gameCount mod 4
        result = case cycleCount:
        of 0:
            "sz"
        of 1:
            "tc"
        of 2:
            "rm"
        of 3:
            "cb"
        else:
            "sz"
        

    for gameIndex in 0..(gameCountPerMatch - 1):
        let currentMode = Mode(getMode(gameCount))

        let possibleMaps = getMapsWithMinimalPlays(currentMode)

        if possibleMaps.len == 0:
            echo "Something went horribly, horribly wrong"
            exitProcess(1)

        let randomMap = sample(possibleMaps)

        let nextGame = Game(mode: string(currentMode), map: string(randomMap))
        ++mapPlayCounts[randomMap]

        currentMatch += nextGame
        ++gameCount
    
    mapList += currentMatch

let modeNames = {"tw": "Turf War", "sz": "Splat Zones", "tc": "Tower Control", "rm": "Rainmaker", "cb": "Clam Blitz"}.toTable()

for matchIndex, match in mapList.matches:
    echo "\nRound ", matchIndex + 1, ": ",match.`type`, " ",match.games.len
    for gameIndex, game in match.games:
        echo gameIndex + 1, ". ", modeNames[game.mode], " on ", game.map

exitProcess(0)
