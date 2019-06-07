function [rects]=placeBoxes(image, centroids, dim, n)
[height, width, ~] = size(image);
rects=zeros(n,4);

    for i=1:n
       llcx=centroids(i,1)-dim(1)/2;
       llcy=centroids(i,2)-dim(2)/2;
       if llcx<0
           llcx=0;
       elseif llcx+dim(1)>width
           llcx=width-dim(1);
       end
       if llcy<0
           llcy=0;
       elseif llcy+dim(2)>height
           llcy=height-dim(2);
       end
       rects(i,:)=[llcx,llcy,dim];
  
       
       
    end



end