extends CanvasLayer

var player_bars := []
var enemy_bars := []


func _ready():
	player_bars = $VBoxContainer/PlayerHUD/HealthBar.get_children()
	enemy_bars = $VBoxContainer/EnemyHUD/HealthBar.get_children()

	update_player_health(10)
	update_enemy_health(10)


func update_player_health(value: int):
	for i in range(player_bars.size()):
		player_bars[i].visible = i < value


func update_enemy_health(value: int):
	for i in range(enemy_bars.size()):
		enemy_bars[i].visible = i < value
