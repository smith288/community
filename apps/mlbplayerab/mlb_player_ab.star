"""
Applet: MLB Player AB
Summary: Show the statistics
Description: For your favorite team, show the current player AB and stats.
Author: smith288
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TEAM = "113"
CACHE_TTL_SECONDS = 30
DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""

PLAYER_IMG = "https://img.mlbstatic.com/mlb-photos/image/upload/d_people:generic:headshot:silo:current.png/r_max/w_240,q_auto:best/v1/people/%s/headshot/silo/current"
API_GAMES = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&startDate="
API_GAME = "https://statsapi.mlb.com/api/v1.1/game/%s/feed/live"
MLBLOGO = base64.decode("""
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
""")
OPENAICACHE = 86400

def main(config):
    team = config.str("fav", DEFAULT_TEAM)
    
    scores = get_scores(API_GAMES, team)
    print("Scores {}".format(len(scores)))
    if scores:
        
        ab = get_current_ab(scores["gamePk"], team)
        statusCode = scores["status"]["statusCode"]
        print("Status: {}".format(statusCode))
        if statusCode == "I" or statusCode == "IR":
            
            return render.Root(     
                render.Stack(
                    children = [
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Box(
                                    height = 32, width = 64, 
                                    child = render.Image(get_cachable_data(PLAYER_IMG % ab["batter"]["info"]["id"]), 80, 80),
                                    )
                                ]
                        ),
                        render.Box(height = 32, width = 64, color = "#00000059"),
                        render.Box (
                            child = render.Column(
                                children = [
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text(ab["batter"]["info"]["initLastName"]),
                                        ]
                                    ),
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text(ab["batter"]["stats"]["stats"]["batting"]["summary"])
                                        ]
                                    ),
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text("AVG: %s HR: %s" % (ab["batter"]["stats"]["seasonStats"]["batting"]["avg"], ab["batter"]["stats"]["seasonStats"]["batting"]["homeRuns"]))
                                        ]
                                    ),
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text("RBI: %s" % ab["batter"]["stats"]["seasonStats"]["batting"]["rbi"])
                                        ]
                                    ),

                                ]
                            ),
                        )
                    ]
                )
            )
        elif scores["status"]["statusCode"] == "S" or scores["status"]["statusCode"] == "P" or scores["status"]["statusCode"] == "PW":
            return render.Root(
                render.Stack(
                    children = [
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [render.Box(
                                height = 32, width = 64, child = render.Image(get_cachable_data(PLAYER_IMG % ab["pitcher"]["info"]["id"]), 64, 64),
                            )]
                        ),
                        render.Box(height = 32, width = 64, color = "#00000059"),
                        render.Box (
                            child = render.Column(
                                children = [
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Marquee(
                                                width = 64,
                                                scroll_direction = "horizontal",
                                                child = render.Text("%s %s" % (ab["pitcher"]["info"]["fullName"], tolocaltime(scores["gameDate"]))),
                                                # offset_start = 1,
                                                # offset_end = 1,
                                            ),
                                        ]
                                    ),

                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text("%s-%s %s" % (ab["pitcher"]["stats"]["seasonStats"]["pitching"]["wins"], ab["pitcher"]["stats"]["seasonStats"]["pitching"]["losses"], ab["pitcher"]["stats"]["seasonStats"]["pitching"]["era"]))
                                        ]
                                    ),

                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text("%s K %s BB" % (ab["pitcher"]["stats"]["seasonStats"]["pitching"]["strikeOuts"], ab["pitcher"]["stats"]["seasonStats"]["pitching"]["baseOnBalls"]))
                                        ]
                                    ),

                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text("%s HR" % (ab["pitcher"]["stats"]["seasonStats"]["pitching"]["homeRuns"]))
                                        ]
                                    ),
                                ]
                            )
                        )
                    ]
                )
            )
        elif scores["status"]["statusCode"] == "F":
            best_performers = get_final_best(ab, team)

            return render.Root(     
                render.Stack(
                    children = [
                        render.Column(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Box(
                                    height = 32, width = 64, 
                                    child = render.Image(get_cachable_data(PLAYER_IMG % best_performers["player"]["id"]), 80, 80),
                                    )
                                ]
                        ),
                        render.Box(height = 32, width = 64, color = "#00000059"),
                        render.Box (
                            child = render.Column(
                                children = [
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.Text(best_performers["player"]["playerName"]),
                                        ]
                                    ),
                                    render.Row(
                                        expanded=True,
                                        main_align="space_evenly",
                                        cross_align="center",
                                        children = [
                                            render.WrappedText(best_performers["summary"], font = "tom-thumb")
                                        ]
                                    ),

                                ]
                            ),
                        )
                    ]
                )
            )
        else:
            return render.Root(
                child = no_game()
            )
    else:
        return render.Root(            
            child = no_game()
        )

def no_game():

    return render.Stack(
        children = [
            render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Box(
                        height = 32, width = 64, 
                        child = render.Image(MLBLOGO, 64, 32),
                        )
                    ]
            ),
            render.Box(height = 32, width = 64, color = "#000000BF"),
            render.Box (
                child = render.Column(
                    children = [
                        render.Row(
                            expanded=True,
                            main_align="space_evenly",
                            cross_align="center",
                            children = [
                                render.WrappedText("No game today", font = "tb-8")
                            ]
                        ),

                    ]
                ),
            )
        ]
    )

    # return render.Box(
    #     render.Row(
    #         expanded=True,
    #         main_align="space_evenly",
    #         cross_align="center",
    #         children = [
    #             render.Image(MLBLOGO, 32, 32),
    #             render.Text("No Game"),
    #         ],
    #     ),
    # )
    

def get_final_best(gamedata, team):
    
    allplayers = []
    homeaway = "away" if int(gamedata["away"]["team"]["id"]) == int(team) else "home"
    allplayers.extend(gamedata[homeaway]["batters"])
    allplayers.extend(gamedata[homeaway]["pitchers"])
    newPlayers = []
    
    
    for _, g in enumerate(allplayers):
        if "batting" in gamedata[homeaway]["players"]["ID%s" %g]["stats"]:
            if "summary" in gamedata[homeaway]["players"]["ID%s" % g]["stats"]["batting"]:
                batting = gamedata[homeaway]["players"]["ID%s" % g]["stats"]["batting"]
                summary = gamedata[homeaway]["players"]["ID%s" % g]["stats"]["batting"]["summary"]
                player = {"playerName": gamedata[homeaway]["players"]["ID%s" % g]["person"]["fullName"], "id": g}
                newPlayers.append({"player": player, "batting": batting, "summary": summary})
        if "pitching" in gamedata[homeaway]["players"]["ID%s" %g]["stats"]:
            if "summary" in gamedata[homeaway]["players"]["ID%s" % g]["stats"]["pitching"]:
                batting = gamedata[homeaway]["players"]["ID%s" % g]["stats"]["pitching"]
                summary = gamedata[homeaway]["players"]["ID%s" % g]["stats"]["pitching"]["summary"]
                player = {"playerName": gamedata[homeaway]["players"]["ID%s" % g]["person"]["fullName"], "id": g}
                newPlayers.append({"player": player, "pitching": batting, "summary": summary})
    allplayers = newPlayers
    
    bestplayer = player_of_game(allplayers, team)
    return bestplayer

def player_of_game(allplayers, team):

    # Point system weights for hitting
    points_runs = 1
    points_hit = .75
    points_bb = .5
    points_hr = 2
    points_hbp = .5
    points_dbl = 1
    points_trpl = 1.75
    points_sb = .5
    points_rbi = .25
    points_sacs = .25
    points_k = .25

    # Point system weights for pitching
    points_k = .25
    points_ip = 1
    points_cg = 2
    points_shutout = 2
    points_pickoff = 1
    points_save = 1
    points_hold = 1
    points_w = 1
    points_earnedr = .05
    
    # Initialize variables to track the best player and their points
    best_player = None
    best_player_name = None
    best_points = 0

    # Loop through each object in the JSON
    for obj in allplayers:
        # Extract player information
        player_name = obj['player']['playerName']
        batting = obj["batting"] if "batting" in obj else None
        pitching = obj["pitching"] if "pitching" in obj else None

        # Calculate points based on the summary
        points = 0

        if batting:
            points += (points_runs * int(batting["runs"]))
            points += (points_hit * int(batting["hits"]))
            points += (points_bb * int(batting["baseOnBalls"]))
            points += (points_hr * int(batting["homeRuns"]))
            points += (points_hbp * int(batting["hitByPitch"]))
            points += (points_dbl * int(batting["doubles"]))
            points += (points_trpl * int(batting["triples"]))
            points += (points_sb * int(batting["stolenBases"]))
            points += (points_rbi * int(batting["rbi"]))
            points += (points_sacs * int(batting["sacBunts"]) + int(batting["sacFlies"]))
            points += (points_sb * int(batting["stolenBases"]))
            points -= (points_k * int(batting["strikeOuts"]))
        elif pitching:
            points += (points_k * int(pitching["strikeOuts"]))
            points += (points_ip * float(pitching["inningsPitched"]))
            points += (points_cg * int(pitching["completeGames"]))
            points += (points_shutout * int(pitching["shutouts"]))
            points += (points_pickoff * int(pitching["pickoffs"]))
            points += (points_save * int(pitching["saves"]))
            points += (points_hold * int(pitching["holds"]))
            points += (points_w) * int(pitching["wins"])
            points -= (points_earnedr*float(pitching["inningsPitched"])) * int(pitching["earnedRuns"])

        print("%s %s %s" % (obj["player"]["playerName"], points, obj['summary']))
        # Check if this player has the best game so far
        if points > best_points:
            best_points = points
            best_player = obj

    # Print the best player and their points
    print("Best player:", best_player["player"]["playerName"])
    print("Points earned:", best_points)

    return best_player

def get_current_ab(gamePk, team):
    data = get_cachable_data(API_GAME % gamePk)
    decodedata = json.decode(data)
    
    gameStatus = decodedata["gameData"]["status"]["statusCode"]
    if gameStatus == "I" or gameStatus == "IR":

        # currentstatus = decodedata["liveData"]["plays"]["currentPlay"]["result"]["type"]
        homeaway = "away" if decodedata["liveData"]["plays"]["currentPlay"]["about"]["isTopInning"] == "true" else "away"
        batter_id = decodedata["liveData"]["plays"]["currentPlay"]["matchup"]["batter"]["id"]
        pitcher_id = decodedata["liveData"]["plays"]["currentPlay"]["matchup"]["pitcher"]["id"]

    elif gameStatus == "S" or gameStatus == "P" or gameStatus == "PW":
        batter_id = 0
        if int(decodedata["gameData"]["teams"]["away"]["id"]) == int(team):
            pitcher_id = decodedata["gameData"]["probablePitchers"]["away"]["id"]
        else:
            pitcher_id = decodedata["gameData"]["probablePitchers"]["home"]["id"]
    elif gameStatus == "F":
        return decodedata["liveData"]["boxscore"]["teams"]

    if "ID%s" % batter_id in decodedata["liveData"]["boxscore"]["teams"]["home"]["players"]:
        batter_stats = decodedata["liveData"]["boxscore"]["teams"]["home"]["players"]["ID%s" % batter_id] if batter_id > 0 else {}
        
    else:
        batter_stats = decodedata["liveData"]["boxscore"]["teams"]["away"]["players"]["ID%s" % batter_id] if batter_id > 0 else {}
        
    if "ID%s" % pitcher_id in decodedata["liveData"]["boxscore"]["teams"]["home"]["players"]:
        pitcher_stats = decodedata["liveData"]["boxscore"]["teams"]["home"]["players"]["ID%s" % pitcher_id]
    else:
        pitcher_stats = decodedata["liveData"]["boxscore"]["teams"]["away"]["players"]["ID%s" % pitcher_id]

    batter = decodedata["gameData"]["players"]["ID%s" % batter_id] if "ID%s" % batter_id in decodedata["gameData"]["players"] else {}
    pitcher = decodedata["gameData"]["players"]["ID%s" % pitcher_id] if "ID%s" % pitcher_id in decodedata["gameData"]["players"] else {}

    # print(pitcher_id)
    ab_data = {"batter": {"info": batter, "stats": batter_stats}, "pitcher": {"info": pitcher, "stats": pitcher_stats}}
    # print(ab_data)
    return ab_data


def get_scores(url, team):
    allscores = []
    gameCount = 0
    
    print("Url: {}".format(url))
    data = get_cachable_data(url)
    decodedata = json.decode(data)
    allscores.extend(decodedata["dates"][0]["games"])
    if team != "":
        newScores = []
        for _, s in enumerate(allscores):
            
            home = s["teams"]["home"]["team"]["id"]
            away = s["teams"]["away"]["team"]["id"]
            gameStatus = s["status"]["statusCode"]
            # print("Game %s home %s away %s fav %s" % (gameStatus, home, away, team))
            if (int(home) == int(team) or int(away) == int(team)) and (gameStatus == "S" or gameStatus == "I" or gameStatus == "P" or gameStatus == "PW" or gameStatus == "F" or gameStatus == "IR"):
                return s
    
    return {}

def get_cachable_data(url, json_body = {}, headers = {}, ttl_seconds = CACHE_TTL_SECONDS, method = "GET"):
    key = base64.encode(url)

    data = cache.get(key)
    if data != None:
        print("Cache found for %s" % url)
        return base64.decode(data)

    if method == "GET":
        res = http.get(url = url)
    elif method == "POST": 
        res = http.post(url = url, headers = headers, json_body = json_body)

    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    cache.set(key, base64.encode(res.body()), ttl_seconds = ttl_seconds)

    return res.body()

def tolocaltime(tm):
    parts = tm.split("T")
    date_parts = parts[0].split("-")
    time_parts = parts[1].rstrip("Z").split(":")
    
    year = int(date_parts[0])
    month = int(date_parts[1])
    day = int(date_parts[2])
    hour = int(time_parts[0])
    minute = int(time_parts[1])
    second = int(time_parts[2])
    
    timestamp = time.parse_time(tm).in_location("America/New_York")
    
    local_time = timestamp.format("3:04 PM")
    return local_time   


def get_schema():
    teams = [
        schema.Option(
        display = "ARI",
        value = "109",
        ),
        schema.Option(
            display = "ATL",
            value = "144",
        ),
        schema.Option(
            display = "BAL",
            value = "110",
        ),
        schema.Option(
            display = "BOS",
            value = "111",
        ),
        schema.Option(
            display = "CHC",
            value = "112",
        ),
        schema.Option(
            display = "CIN",
            value = "113",
        ),
        schema.Option(
            display = "CLE",
            value = "114",
        ),
        schema.Option(
            display = "COL",
            value = "115",
        ),
        schema.Option(
            display = "CWS",
            value = "145",
        ),
        schema.Option(
            display = "DET",
            value = "116",
        ),
        schema.Option(
            display = "HOU",
            value = "117",
        ),
        schema.Option(
            display = "KC",
            value = "118",
        ),
        schema.Option(
            display = "LAA",
            value = "108",
        ),
        schema.Option(
            display = "LAD",
            value = "119",
        ),
        schema.Option(
            display = "MIA",
            value = "146",
        ),
        schema.Option(
            display = "MIL",
            value = "158",
        ),
        schema.Option(
            display = "MIN",
            value = "142",
        ),
        schema.Option(
            display = "NYM",
            value = "121",
        ),
        schema.Option(
            display = "NYY",
            value = "147",
        ),
        schema.Option(
            display = "OAK",
            value = "133",
        ),
        schema.Option(
            display = "PHI",
            value = "143",
        ),
        schema.Option(
            display = "PIT",
            value = "134",
        ),
        schema.Option(
            display = "SD",
            value = "135",
        ),
        schema.Option(
            display = "SEA",
            value = "136",
        ),
        schema.Option(
            display = "SF",
            value = "137",
        ),
        schema.Option(
            display = "STL",
            value = "138",
        ),
        schema.Option(
            display = "TB",
            value = "139",
        ),
        schema.Option(
            display = "TEX",
            value = "140",
        ),
        schema.Option(
            display = "TOR",
            value = "141",
        ),
        schema.Option(
            display = "WSH",
            value = "120",
        )
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "fav",
                name = "Favorite Team?",
                desc = "Favorite team to show when their game is playing.",
                icon = "user",
                default = teams[23].value,
                options = teams,
            ),
        ],
    )
