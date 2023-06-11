clear all
LineWidth = 3; MarkerSize = 8; FontSize = 14;

encodingList = "What is the Encoding Scheme(enter from 1 - 8)?\n1 = NRZ-I\n" + ...
    "2 = NRZ-L\n3 = AMI\n4 = Pseudoternary\n5 = Manchester\n6 = Differential Manchester\n7 = B8ZS\n8 = HDB3\n" ;
encodingMod = input(encodingList);
if isempty(encodingMod)
    encodingMod = 3;
end
selectedDataString = "Enter the data String:\n";
dataString = input(selectedDataString, "s");

% Verifying if the dataString only contains 1s and 0s

if isempty(regexp(dataString,'[^01]','once')) % Checks for any violations

numberOfBits = length(dataString);
if isempty(dataString)
    dataString = "";
    numberOfBits = 10;
    for i=1:numberOfBits
        if mod(i,2) == 0
        dataString = dataString + "0";
        else
        dataString = dataString + "1";
        end
    end
end
bitStream  = [];
for j=1:numberOfBits
    char_list = reshape(char(dataString),1,[]);
    s = char_list(j);
    bitStream(j) = str2num(s);
end 
disp(bitStream);
HighV = +5; ZeroV = 0; LowV = -5;
Signal = [];
x = [];
Tb = 1; % Time to receive the next bit
prePulse = HighV;
prePulse2 = LowV; %B8ZS & HDB3
x = [x 0]; % initial condition
Signal = [Signal HighV]; % initial condition except for B8ZS & HDB3

switch encodingMod
    case 1 %NRZ-I
        for i=1:numberOfBits
          if bitStream(i)==1
            if prePulse == HighV
                prePulse = ZeroV;
            else
                prePulse = HighV;
            end
          end
          Signal = [Signal prePulse];
        end
       

    case 2 %NRZ-L
        for i=1:numberOfBits
          if bitStream(i)==0
            Signal = [Signal HighV];
          else Signal = [Signal ZeroV];
          end
        end
        
    case 3 %AMI
        for i=1:numberOfBits
          if bitStream(i)==1
              %  prePulse = -prePulse;
              % Signal = [Signal prePulse];
              % -- The above method works the same --
              Signal = [Signal -prePulse];
              prePulse = -prePulse;
          else
              Signal = [Signal ZeroV];
          end
        end
    
    case 4 %Pseudoternary
        for i=1:numberOfBits
          if bitStream(i)==0
              Signal = [Signal -prePulse];
              prePulse = -prePulse;
          else
              Signal = [Signal ZeroV];
          end
        end

    case 5 %Manchester
        for i=1:numberOfBits
          if bitStream(i)==0
             Signal = [Signal HighV LowV];
          else
             Signal = [Signal LowV HighV];
          end
        end
    
    case 6 %Differential Manchester
        for i=1:numberOfBits
          if bitStream(i)==0
            Signal = [Signal -prePulse prePulse];
          else
            Signal = [Signal prePulse -prePulse];
            prePulse = -prePulse;
          end
        end

    case 7 %B8ZS 
        Signal(1) = LowV; 
        Zerocounter = 0; %To counts the number of Zeros
        for i=1:numberOfBits
          if bitStream(i)==0
              Signal = [Signal ZeroV];
              Zerocounter = Zerocounter + 1;
            if Zerocounter==8
              Signal(i-3) = prePulse2;
              Signal(i-2) = -prePulse2;
              prePulse2 = -prePulse2;
              Signal(i) = prePulse2;
              Signal(i+1) = -prePulse2;
              prePulse2 = -prePulse2;
              Zerocounter = 0;
            end
          else
            Zerocounter = 0;
            Signal = [Signal -prePulse2];
            prePulse2 = -prePulse2;
          end
        end
  
    case 8 %HDB3
        Signal(1) = LowV; 
        Zerocounter = 0;
        pulse = 1; %odd 1s
        for i=1:numberOfBits
          if bitStream(i)==0
               Signal = [Signal ZeroV];
               Zerocounter = Zerocounter + 1;
            if Zerocounter==4
              if(mod(pulse, 2)==0)
                Signal(i+1) = -prePulse2;
                prePulse2 = -prePulse2;
                Signal(i-2) = prePulse2;
                Zerocounter = 0;
                pulse = 0;
              else
                Signal(i+1) = prePulse2;
                Zerocounter = 0;
                pulse = 0;
              end
            end
          else
            Zerocounter = 0;
            Signal = [Signal -prePulse2];
            prePulse2 = -prePulse2;
            pulse = pulse + 1;
          end
        end
end
for i=1:numberOfBits
    if encodingMod == 5 || encodingMod == 6
        x = [x (Tb*(i-1)) Tb*(i-0.5)];
    else
        x = [x Tb*(i-1)];
    end
end
Signal = [Signal Signal(length(Signal))];
x = [x numberOfBits];

% Calculate the Average Transition per Bit
totalTransition = 0;
for i=1:length(Signal)-1
    if Signal(i) ~= Signal(i+1)
        totalTransition = totalTransition + 1;
    end
end

avgTransition = totalTransition/numberOfBits;
fprintf("Total Transition = " + totalTransition + "\nAverage Transition = " + avgTransition + "\n");
stairs(x, Signal, 'LineWidth', LineWidth);
xticks(1:1:numberOfBits+1);
grid on
axis([0 numberOfBits 1.2*LowV 1.2*HighV]);
xlabel('bit number'); ylabel('s(t) - volts');
set(gca, 'FontSize', FontSize);

else
    disp("dateString contains characters other than 0s and 1s")
end