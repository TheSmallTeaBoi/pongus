const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

const Ball = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: f32,
};

const Score = struct {
    left_score: u8,
    right_score: u8,
};

const WINHEIGHT: i16 = 600;
const WINWIDTH: i16 = 800;
const ball_speed: i8 = 8;

var paddle_l: u16 = WINHEIGHT / 2;
var paddle_r: u16 = WINHEIGHT / 2;

var prng: std.Random.DefaultPrng = .init(888);
const rand = prng.random();

pub fn main() void {
    rl.InitWindow(WINWIDTH, WINHEIGHT, "Pongus");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    var my_ball = Ball{ .position = .{
        .x = WINWIDTH / 2,
        .y = WINHEIGHT / 2,
    }, .velocity = .{
        .x = ball_speed,
        .y = @as(f32, @floatFromInt(rand.intRangeAtMost(i8, 6, 10))),
    }, .size = 4 };

    var score_buffer: [64]u8 = undefined;
    var scoreboard = Score{ .left_score = 0, .right_score = 0 };

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        scoreboard = calculate_score(my_ball, scoreboard);

        rl.DrawText(std.fmt.bufPrintZ(&score_buffer, "{d}", .{scoreboard.left_score}) catch unreachable, WINWIDTH / 2 - 50, 100, 24, rl.GRAY);
        rl.DrawText(std.fmt.bufPrintZ(&score_buffer, "{d}", .{scoreboard.right_score}) catch unreachable, WINWIDTH / 2 + 50, 100, 24, rl.GRAY);

        rl.DrawLineDashed(
            .{ .y = 0, .x = WINWIDTH / 2 },
            .{ .y = WINHEIGHT, .x = WINWIDTH / 2 },
            3,
            3,
            rl.GRAY,
        );

        paddle_r = calculate_ai(paddle_r, my_ball);
        paddle_l = calculate_input(paddle_l);

        my_ball = calculate_ball(my_ball);

        drawPaddle(
            0,
            paddle_l,
        );

        drawPaddle(
            WINWIDTH - 25,
            paddle_r,
        );

        rl.DrawCircleV(
            my_ball.position,
            my_ball.size,
            rl.BLACK,
        );

        rl.EndDrawing();
    }
}

fn calculate_ball(ball: Ball) Ball {
    var new_ball = ball;

    const WINMID: rl.Vector2 = .{ .y = WINHEIGHT / 2, .x = WINWIDTH / 2 };

    if (ball.position.x <= 0) {
        return .{ .position = WINMID, .size = 4, .velocity = .{ .x = ball_speed, .y = @as(f32, @floatFromInt(rand.intRangeAtMost(i8, 6, 10))) } };
    } else if (ball.position.x >= WINWIDTH) {
        return .{ .position = WINMID, .size = 4, .velocity = .{ .x = -ball_speed, .y = @as(f32, @floatFromInt(rand.intRangeAtMost(i8, 6, 10))) } };
    }

    const left_paddle = @as(f32, @floatFromInt(paddle_l));
    const right_paddle = @as(f32, @floatFromInt(paddle_r));

    if (new_ball.position.y <= 0 or new_ball.position.y >= WINHEIGHT) {
        new_ball.velocity.y = -new_ball.velocity.y;
    }

    if (new_ball.position.x <= 25 and (new_ball.position.y >= left_paddle - 50 and new_ball.position.y <= left_paddle + 50)) {
        if (new_ball.velocity.x < 0) {
            new_ball.velocity.x = -new_ball.velocity.x;
        }
    }

    if (new_ball.position.x >= 775 and (new_ball.position.y >= right_paddle - 50 and new_ball.position.y <= right_paddle + 50)) {
        if (new_ball.velocity.x > 0) {
            new_ball.velocity.x = -new_ball.velocity.x;
        }
    }

    new_ball.position.x += new_ball.velocity.x;
    new_ball.position.y += new_ball.velocity.y;

    return new_ball;
}

fn calculate_score(ball: Ball, scoreboard: Score) Score {
    var new_scoreboard = scoreboard;
    if (ball.position.x <= 0) {
        new_scoreboard.right_score = scoreboard.right_score + 1;
    } else if (ball.position.x >= WINWIDTH) {
        new_scoreboard.left_score = scoreboard.left_score + 1;
    }

    return new_scoreboard;
}

fn calculate_ai(paddle: u16, ball: Ball) u16 {
    const paddle_y = @as(f32, @floatFromInt(paddle));
    const paddle_speed: u8 = 5;
    var new_paddle: u16 = paddle;
    if (ball.position.y > paddle_y + paddle_speed) {
        if (paddle_y + paddle_speed <= WINHEIGHT - 50) {
            new_paddle = paddle + paddle_speed;
        } else {
            new_paddle = WINHEIGHT - 50;
        }
    } else if (ball.position.y < paddle_y - paddle_speed) {
        if (paddle_y - paddle_speed >= 50) {
            new_paddle = paddle - paddle_speed;
        } else {
            new_paddle = 50;
        }
    }

    return new_paddle;
}

fn calculate_input(paddle: u16) u16 {
    if (rl.IsKeyDown(rl.KEY_UP)) {
        if (paddle - 4 <= 50) {
            return 50;
        }

        return paddle - 4;
    } else if (rl.IsKeyDown(rl.KEY_DOWN)) {
        if (paddle >= WINHEIGHT - 50) {
            return WINHEIGHT - 50;
        }
        return paddle + 4;
    }

    return paddle;
}

fn drawPaddle(posX: u16, posY: u16) void {
    const HEIGHT: u16 = 100;
    rl.DrawRectangle(
        posX,
        posY - (HEIGHT / 2),
        25,
        HEIGHT,
        rl.BLACK,
    );
}
