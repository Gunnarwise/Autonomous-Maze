




%initialize sensors
brick.SetColorMode(3, 2);
brick.GyroCalibrate(2);
  
distance = brick.UltrasonicDist(1);





%%%%%%%%%%%%%%%%%%%
%%% MAIN SCRIPT %%%
%%%%%%%%%%%%%%%%%%%

% PHASE 1: search for blue, then switch to remote
autoDrive(brick, 2);
stopProgram = remoteControl(brick);

% PHASE 2: search for yellow, then switch to remote
if (~stopProgram) 
    autoDrive(brick, 4);
    stopProgram = remoteControl(brick);
end

% PHASE 3: search for green, then end script
if (~stopProgram)
    autoDrive(brick, 3);
end




brick.StopMotor('AB', 'Coast');

%%%%%%%%%%%%%%%%%%%%%%
%%% MAIN FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%

% Function for Autonomous Driving
function autoDrive(brick, colorToLookFor)

% set variables
forwardSpeed = -50;
turnSpeed = 60;
forkliftSpeed = -10;
timeSinceLook = 0;

% bool vals to decide what to do
solvingMaze = true;
manualMode = false;
turning = false;
checkingRightWall = false;


brick.MoveMotor('AB', forwardSpeed); 

while (solvingMaze)
    % update distance
    distance = brick.UltrasonicDist(1);
    timeSinceLook = timeSinceLook + 1;
    [solvingMaze, manualMode] = checkForColors(brick, colorToLookFor);


    % check for opening to the right every 5 seconds
    if (mod(timeSinceLook, 5) == 0)
        checkingRightWall = true;
        brick.MoveMotorAngleRel('D', 50, 90, 'Brake');
        [solvingMaze, manualMode] = checkForColors(brick, colorToLookFor);
        pause(1);
        distance = brick.UltrasonicDist(1);
        [solvingMaze, manualMode] = checkForColors(brick, colorToLookFor);

        % if open path to the right, turn right
        if (distance > 45)
            brick.StopAllMotors('Brake');
            brick.GyroCalibrate(2);
            [solvingMaze, manualMode] = checkForColors(brick, colorToLookFor);
            pause(1.5);
            turnRight(brick);
        end

        % reset dist sensor, start driving again
        brick.MoveMotorAngleRel('D', 50, -90, 'Brake');
        [solvingMaze, manualMode] = checkForColors(brick, colorToLookFor);
        pause(1);
        distance = brick.UltrasonicDist(1);
        checkingRightWall = false;
        brick.MoveMotor('AB', forwardSpeed);
    end


    

    % if wall is close, look for the next turn option
    if (distance < 25 && ~checkingRightWall)
        brick.StopAllMotors('Brake');
        brick.GyroCalibrate(2);
        brick.MoveMotorAngleRel('D', 50, 90, 'Brake');
        pause(2);
        distance = brick.UltrasonicDist(1);

        % if wall to right, check other options
        if (distance < 40)
            brick.MoveMotorAngleRel('D', 50, -180, 'Brake');
            pause(2);
            distance = brick.UltrasonicDist(1);
            pause(0.2);

            % if wall to left, turn around
            if (distance < 40)
                brick.MoveMotorAngleRel('D', 50, 90, 'Brake');
                pause(2);
                distance = brick.UltrasonicDist(1);
                turnAround(brick);
                pause(1);
                brick.MoveMotor('AB', forwardSpeed);

            % if no wall to left, turn left
            else
                brick.MoveMotorAngleRel('D', 50, 90, 'Brake');
                pause(2);
                turnLeft(brick);
                pause(1);
                brick.MoveMotor('AB', forwardSpeed);
            end

        % if no wall to right, turn right
        else 
            brick.MoveMotorAngleRel('D', 50, -90, 'Brake');
            pause(2);
            distance = brick.UltrasonicDist(1);
            turnRight(brick);
            pause(1);
            brick.MoveMotor('AB', forwardSpeed);
        end

        
       
    end
    pause(0.2);
end

end


% Function for Remote Control Driving



function stopProgram = remoteControl(brick)

% initialize keyboard
global key
InitKeyboard();
% set variables
forwardSpeed = -50;
turnSpeed = 60;
forkliftSpeed = -10;
timeSinceLook = 0;

% bool vals to decide what to do
solvingMaze = false;
manualMode = true;
turning = false;
checkingRightWall = false;


while(manualMode)
pause(0.1);
    
    % check keys for press
    switch key
        % w moves forward
        case 'w'
            brick.MoveMotor('AB', forwardSpeed);
            
        % d moves right
        case 'd'
            brick.MoveMotor('A', -turnSpeed);
            brick.MoveMotor('B', turnSpeed);
        
        % a moves left
        case 'a'
            brick.MoveMotor('A', turnSpeed);
            brick.MoveMotor('B', -turnSpeed);

        % s moves backwards
        case 's'
            brick.MoveMotor('AB', -forwardSpeed);

        % e lifts forklift
        case 'e'
            brick.MoveMotor('C', forkliftSpeed);

        % q lowers forklift
        case 'q'
            brick.MoveMotor('C', -forkliftSpeed);

        % p ends manual mode
        case 'x'
            manualMode = false;
            stopProgram = true;
            break;

        case 'c'
            stopProgram = false;
            manualMode = false;
            break;

        case 'rightarrow'
            brick.MoveMotor('D', 10);
            
        case 'leftarrow'
            brick.MoveMotor('D', -10);

            
        % dont move if nothing is pressed
        case 0
            brick.StopAllMotors('Brake');

    end


end

end








%%%%%%%%%%%%%%%%%%%%%%%
%%% OTHER FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%


%%% checks for colors: Red-pause, input one other color to stop for %%%
function [solvingMaze, manualMode] = checkForColors(brick, secondColor)
forwardSpeed = -50;
% pause at color red
    if (brick.ColorCode(3) == 5)
        brick.StopMotor('AB', 'Brake');
        pause(2);
        brick.MoveMotor('AB', forwardSpeed);
        pause(1);
        solvingMaze = true;
        manualMode = false;

    % manual mode at color blue
    elseif (brick.ColorCode(3) == 2 && secondColor == 2)
        brick.StopAllMotors('Brake');
        brick.beep();
        pause(0.5);
        brick.beep();
        solvingMaze = false;
        manualMode = true;

    elseif (brick.ColorCode(3) == 3 && secondColor == 3)
        brick.StopAllMotors('Brake');
        brick.beep();
        pause(0.5);
        brick.beep();
        pause(0.5);
        brick.beep();
        solvingMaze = false;
        manualMode = true;
    elseif (brick.ColorCode(3) == 4 && secondColor == 4)
        brick.StopAllMotors('Brake');
        brick.beep();
        pause(0.5);
        brick.beep();
        pause(0.5);
        brick.beep();
        pause(0.5);
        brick.beep();
        solvingMaze = false;
        manualMode = true;
    
    
    else
        solvingMaze = true;
        manualMode = false;
    end
end



%%% Turn Right 90 degrees %%%
function turnRight(brick)
turnSpeed = 60;
turning = true;
brick.MoveMotor('A', -turnSpeed);
brick.MoveMotor('B', turnSpeed);

% loop until not turning
while (turning)

    % if 90 degrees from start
    if (brick.GyroAngle(2) > 90)
        % change to forward drive
        brick.StopMotor('AB', 'Brake');
        turning = false;
      
        %brick.MoveMotor('AB', forwardSpeed);

    end
end

end

%%% Turn left 90 degrees %%%
function turnLeft(brick)
turnSpeed = 60;
turning = true;
brick.MoveMotor('A', turnSpeed);
brick.MoveMotor('B', -turnSpeed);

% loop until not turning
while (turning)

    % if 90 degrees from start
    if (brick.GyroAngle(2) < -90)
        % change to forward drive
        brick.StopMotor('AB', 'Brake');
        turning = false;
     
        %brick.MoveMotor('AB', forwardSpeed);

    end
end

end


%%% turn 180 degrees %%%

function turnAround(brick)
turnSpeed = 60;
turning = true;
brick.MoveMotor('A', -turnSpeed);
brick.MoveMotor('B', turnSpeed);

% loop until not turning
while (turning)

    % if 90 degrees from start
    if (brick.GyroAngle(2) > 180)
        % change to forward drive
        brick.StopMotor('AB', 'Brake');
        turning = false;

        %brick.MoveMotor('AB', forwardSpeed);

    end
end

end


