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

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    pipe <- pipe_initialize()
    space_init()
    set_window_title("death_pipe")
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    var delta = get_mouse_position().x - float(get_screen_width()) * 0.5
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

    pipe_act(pipe, dt)

    if !gameOver && check_collision(pipe)
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
    debug_out("{get_mouse_position()}")
