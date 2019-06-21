function [outHSV]=enhanceLuminance(HSV)


V=HSV(:,:,3);
Vv=reshape(V,1,numel(V));
L=quantile(Vv,0.1);
if L<=50
    z=0;
elseif L>50 && L<=150
    z=(L-50)/100;
else
    z=1;
end


V2=(V.^(0.75*z+0.25)+0.4*(1-z)*(1-V)+V.^(2-z))/2;
outHSV=HSV;
outHSV(:,:,3)=V2;