clc;
clear;
close all;

imgin = im2double(imread('./large1.jpg'));

[imh, imw, nb] = size(imgin);
assert(nb==1);
% the image is grayscale

V = zeros(imh, imw);
V(1:imh*imw) = 1:imh*imw;
% V(y,x) = (y-1)*imw + x
% use V(y,x) to represent the variable index of pixel (x,y)
% Always keep in mind that in matlab indexing starts with 1, not 0

b = zeros(imh*imw, 1);
e = 1;
index = 1;
% total # of i, j, v = (imh-1)*(imw-1)*4 + (imh-1)*2 + (imw-1)*2 + 4; 
i = zeros(1, (imh-1)*(imw-1)*4 + (imh-1)*2 + (imw-1)*2 + 4);
j = zeros(1, (imh-1)*(imw-1)*4 + (imh-1)*2 + (imw-1)*2 + 4);
v = zeros(1, (imh-1)*(imw-1)*4 + (imh-1)*2 + (imw-1)*2 + 4);


% inner
for y = 2 : imh-1
    for x = 2 : imw-1
        % i = [i, e,      e,          e           e,          e];
        % j = [j, V(y,x), V(y,x+1),   V(y,x-1),   V(y+1,x),   V(y-1,x)];
        % v = [v, 4,      -1,         -1,         -1,         -1];
        i(index : index+4) = [e,      e,          e           e,          e];
        j(index : index+4) = [V(y,x), V(y,x+1),   V(y,x-1),   V(y+1,x),   V(y-1,x)];
        v(index : index+4) = [4,      -1,         -1,         -1,         -1];
        b(e, 1) = 4*imgin(y,x) - imgin(y,x+1) - imgin(y,x-1) - imgin(y+1,x) - imgin(y-1,x);

        index = index + 5;
        e = e + 1;
    end
end
% first row + last row:
for x = 2 : imw-1
    i(index : index+2) = [e,      e,        e];
    j(index : index+2) = [V(1,x), V(1,x+1), V(1,x-1)];
    v(index : index+2) = [2,      -1,       -1];
    b(e, 1) = 2*imgin(1,x) - imgin(1,x+1) - imgin(1,x-1);
    index = index + 3;
    e = e + 1;

    i(index : index+2) = [e,        e,          e];
    j(index : index+2) = [V(imh,x), V(imh,x+1), V(imh,x-1)];
    v(index : index+2) = [2,        -1,         -1];
    b(e, 1) = 2*imgin(imh,x) - imgin(imh,x+1) - imgin(imh,x-1);
    index = index + 3;
    e = e + 1;
end
% first col + last col
for y = 2 : imh-1
    i(index : index+2) = [e,      e,        e];
    j(index : index+2) = [V(y,1), V(y+1,1), V(y-1,1)];
    v(index : index+2) = [2,      -1,       -1];
    b(e, 1) = 2*imgin(y,1)  - imgin(y+1,1) - imgin(y-1,1);
    index = index + 3;
    e = e + 1;

    i(index : index+2) = [e,        e,          e];
    j(index : index+2) = [V(y,imw), V(y+1,imw), V(y-1,imw)];
    v(index : index+2) = [2,        -1,         -1];
    b(e, 1) = 2*imgin(y,imw) - imgin(y+1,imw) - imgin(y-1,imw);
    index = index + 3;
    e = e + 1;
end

% 4 corners
i(index : index+3) = [e,      e+1,      e+2,      e+3];
j(index : index+3) = [V(1,1), V(1,imw), V(imh,1), V(imh,imw)];
v(index : index+3) = [1,      1,        1,        1];
b(e, 1) = imgin(1,1); % left top
b(e+1, 1) = imgin(1,imw); % right top
b(e+2, 1) = imgin(imh,1); % left bottom
b(e+3, 1) = imgin(imh,imw); % right bottom
e = e + 4;

A = sparse(i,j,v);

%use "lscov" or "\", please google the matlab documents
solution = A\b;
error = sum(abs(A*solution-b));
disp(error)
imgout = reshape(solution,[imh,imw]);
imwrite(imgout,'output.png');

f = figure(), hold off,

subplot(3,2,1); imshow(imgin); title("Ground Truth");
subplot(3,2,2); imshow(imgout); title("Similar Ground Truth");

reconstructions = {'Globally Brighter'; 'Brighter on Left'; 'Brighter on Bottom'; 'Brighter on Right Bottom Corner'};
for i = 1:4
    copy_b = b;
    switch i
        case 1 %'Globally brighter'
            copy_b(end-3:end) = copy_b(end-3:end) + 0.3;
        case 2 % 'Brighter on left'
            copy_b(end-3) = copy_b(end-3) + 0.5;
            copy_b(end-1) = copy_b(end-1) + 0.5;
        case 3 %'Brighter on bottom'
            copy_b(end-1:end) = copy_b(end-1:end) + 0.5;
        case 4 %'Brighter on right bottom corner'
            copy_b(end) = copy_b(end) + 0.5;
    end
    solution = A\copy_b;

    imgout = reshape(solution,[imh,imw]);
    subplot(3,2,i+2), imshow(imgout); title(reconstructions(i));
end

saveas(f, 'output_all.png');