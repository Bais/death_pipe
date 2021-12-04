require daslib/media
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code
require pipe
require debugOut
require camera
require space


var
    pipe : Pipe
    camera : Camera
    gameOver : bool
    music : SoundHandle
    playMusic : PlayingSoundHandle
    endSound : PcmSound
    score : float 

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    music <- create_managed_sound("res/music.mp3")
    endSound <- create_sound("res/end.mp3")
    pipe <- pipe_initialize()
    space_init()
    set_window_title("death_pipe")
    playMusic = play_sound_loop(music, 1.0)
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(var dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    if gameOver
        dt *= 0.3
        if get_mouse_button_down(MB_LEFT)
            gameOver = false
            score = 0.0
            playMusic = play_sound_loop(music, 1.0)

    else
        score += dt * 10.0

    var delta = float(get_screen_width()) * 0.5 - get_mouse_position().x
    let threshold = 5.0
    if delta > threshold
        delta -= threshold
    elif delta < -threshold
        delta += threshold
    else
        delta = 0.0
    
    delta /= float(get_screen_width())

    if !gameOver
        pipe_move_user(pipe, delta * dt)

    pipe_act(pipe, dt * (300.0 + score) / 300.0 )

    if !gameOver && check_collision(pipe)
        stop_sound(playMusic)
        play_sound(endSound)
        gameOver = true


// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    debug_out_start()
    setUpCamera(pipe, camera)
    camera_draw(camera)
    render_space(camera)
    pipe_draw(pipe, camera)
    set_font_size(40)
    text_out(50, 50, "Score: {int(score)}", 0xffffffff)
    if gameOver
        set_font_size(100)
        text_out(500, 500, "Game Over", 0xffaa0000)
