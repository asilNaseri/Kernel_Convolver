clear; clc; close all;

%% Generics & Constants

coefWidth = 8;

dataNum = 20;
batchNum = 10;

%% Input Generation

coef = zeros(3, 3, batchNum);
inverse_divisor = zeros(1, batchNum);
for i = 1 : batchNum
    while (sum(coef(:, :, i), 'all') <= 0)
        coef(:, :, i) = randi([-2 ^ (coefWidth - 1), 2 ^ (coefWidth - 1) - 1], 3, 3);
    end
    inverse_divisor(i) = round(2 ^ 16 / sum(coef(:, :, i), 'all'));
end

pixelIn = randi([0 255], 3, 3, dataNum, batchNum);

inputFile = fopen('input_data.txt', 'w');
fprintf(inputFile, [repmat('%-10d\t', 1, 1 + 1 + 9 + 1 + 9) '\n'], zeros(1 + 1 + 9 + 1 + 9, 100));

for i = 1:batchNum
    fprintf(inputFile, [repmat('%-10d\t', 1, 1 + 1 + 9 + 1 + 9) '\n'], [1; inverse_divisor(i); reshape(coef(:, :, i), 9, 1); zeros(1 + 9, 1)]);
    for j = 1:dataNum
        fprintf(inputFile, [repmat('%-10d\t', 1, 1 + 1 + 9 + 1 + 9) '\n'], [zeros(1 + 1 + 9, 1); 1; reshape(pixelIn(:, :, j, i), 9, 1)]);
    end
    fprintf(inputFile, [repmat('%-10d\t', 1, 1 + 1 + 9 + 1 + 9) '\n'], zeros(1 + 1 + 9 + 1 + 9, 50));
end

fprintf(inputFile, [repmat('%-10d\t', 1, 1 + 1 + 9 + 1 + 9) '\n'], zeros(1 + 1 + 9 + 1 + 9, 100));
fclose(inputFile);

%% Matlab Ouput

dataOutMatlab = zeros(dataNum, batchNum);
for i = 1:batchNum
    dataOutMatlab(:, i) = round(sum(sum(repmat(coef(:, :, i), 1, 1, dataNum) .* pixelIn(:, :, :, i), 1), 2) * inverse_divisor(i) / (2^16)); 
end

dataOutMatlab(dataOutMatlab < 0) = 0;
dataOutMatlab(dataOutMatlab > 255) = 255;

%% Simulation

appendText = [' -GcoefWidth=' num2str(coefWidth)];
fid = fopen('../tcl/KernelConvolver.tcl', 'r');

lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'vsim') 
        line = [line, appendText]; 
    end
    lines{end+1} = line; 
end
fclose(fid);

fid = fopen('run.tcl', 'w');
fprintf(fid, '%s\n', lines{:});
fclose(fid);

!start vsim -do run.tcl
pause

%% Output Validation

outputFile = fopen('output_data.txt', 'r');
dataOutVhdl = fscanf(outputFile, '%d');
fclose(outputFile);

error = dataOutVhdl ~= dataOutMatlab(:);

plot(error)
title('Error')

if sum(error) == 0
    disp("No Error Occurred")
else
    disp("Error Occurred")
end