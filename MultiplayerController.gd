extends Control

@export var Address = "agencyboz.com"
@export var port = 5171
var peer

# Called when the node enters the scene tree for the first time.
func _ready():
    multiplayer.peer_connected.connect(peer_connected)
    multiplayer.peer_disconnected.connect(peer_disconnected)
    multiplayer.connected_to_server.connect(connected_to_server)
    multiplayer.connection_failed.connect(connection_failed)
    if "--server" in OS.get_cmdline_args():
        hostGame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func hostGame():
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(port)
    if error != OK:
        print("cannot host: " + error)
        return
        
    peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

    multiplayer.set_multiplayer_peer(peer)
    print('waiting for players')

@rpc("any_peer")
func sendPlayerInformation(name, id):
    if !GameManager.Players.has(id):
        GameManager.Players[id] ={
            "name" : name,
            "id" : id,
            "score": 0
        }
    
    if multiplayer.is_server():
        for i in GameManager.Players:
            sendPlayerInformation.rpc(GameManager.Players[i].name, i)

    # print(GameManager.Players)

@rpc("any_peer", "call_local")
func startGame():
    var scene = load("res://testScene.tscn").instantiate()
    get_tree().root.add_child(scene)
    self.hide()

# this gets called on the server and clients
func peer_connected(id):
    print("player connected: " + str(id))
        
# this gets called on the server and clients
func peer_disconnected(id):
    print("player disconnected: " + str(id))
    GameManager.Players.erase(id)
    var players = get_tree().get_nodes_in_group("Player")
    for i in players:
        if i.name == str(id):
            i.queue_free()

# this get called only from client
func connected_to_server():
    print("connected to server")
    sendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

# this get called only from client
func connection_failed():
    print("connection failed")

func _on_host_button_down():
    hostGame()
    sendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())

func _on_join_button_down():
    peer = ENetMultiplayerPeer.new()
    peer.create_client(Address, port)
    peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
    multiplayer.set_multiplayer_peer(peer)


func _on_start_game_button_down():
    startGame.rpc()
