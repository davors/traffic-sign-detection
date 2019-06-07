function SaliencyDetection(image_id)
    
    name = sprintf('%07.0f.jpg',image_id);
    prefix = '../data/preprocessed_heq_cc/';
    I = imread([prefix, name]);
    

    % Red
    T1 = I(:,:,1)-I(:,:,2)>=50;
    %figure, imshow(T1)

    T2 = I(:,:,1)-I(:,:,3)>=50;
    %figure, imshow(T2)
    
    %T3 = (I(:,:,1)<=200).*(I(:,:,1)>=100);
    T3 = (I(:,:,1)<=200) & (I(:,:,1)>=100);
    %figure, imshow(T3)
    
    %T4 = (I(:,:,1)>=50).*(I(:,:,2)<20).*(I(:,:,3)<20);
    T4 = (I(:,:,1)>=50)&(I(:,:,2)<20)&(I(:,:,3)<20);
    %figure, imshow(T4)
    
    T5 = (I(:,:,1)>=I(:,:,2)).*(I(:,:,1)>=I(:,:,3));
    %figure, imshow(T5)
    
    R = T1.*T2.*T3.*T5+T4;
    %figure, imshow(R)
    %close all

    %figure, imshow(I)
    
    
    % Blue
    T1 = I(:,:,3)-I(:,:,1)>=64;
    %figure, imshow(T1)

    T2 = I(:,:,3)-I(:,:,2)>=64;
    %figure, imshow(T2)
    
    T3 = I(:,:,1)<=100;
    %figure, imshow(T3)
    
    T4 = I(:,:,2)<=110;
    %figure, imshow(T4)
    
    B = T1.*T2.*T3.*T4;
    %figure, imshow(B)
    
    %close all

    %figure, imshow(I)
    
    % Yellow
    T1 = I(:,:,1)-I(:,:,3)>=100;
    %figure, imshow(T1)

    T2 = I(:,:,1)-I(:,:,3)>=100;
    %figure, imshow(T2)
    
    T3 = (I(:,:,3)<=30).*(I(:,:,2)<=30);
    %figure, imshow(T3)
    
    Y = T1.*T2.*T3;
    %figure, imshow(Y)
    
    close all
    
%     % Black
%     T1 = I(:,:,1)<=10;
%     figure, imshow(T1)
% 
%     T2 = I(:,:,2)<=10;
%     figure, imshow(T2)
%     
%     T3 = I(:,:,3)<=10;
%     figure, imshow(T3)
%     
%     K = T1.*T2.*T3;
%     figure, imshow(K)

     F = R + B + Y;
     
     figure();
     subplot(2,2,1); imshow(R); title('red');
     subplot(2,2,2); imshow(B); title('blue');
     subplot(2,2,3); imshow(Y); title('yellow');
     subplot(2,2,4); imshow(F); title('Union');
     
     %imwrite(F, ['ex/', name], 'jpg');
end

