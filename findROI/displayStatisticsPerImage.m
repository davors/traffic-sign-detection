function displayStatisticsPerImage(statistics,file_name)

if ~exist('file_name','var') || isempty(file_name)
    file = 1;
else
    file = fopen(file_name, 'w');
end

img_stat=statistics.per_image;
fprintf(file,"Image\tCovered\tPartially covered\tNot covered\tCovered area\tTotal signs\n");
for image_i=1:numel(img_stat)
    img_covered=img_stat{image_i}.covered_signs;
    img_part_covered=img_stat{image_i}.partially_covered_signs;
    img_area=img_stat{image_i}.covered_area;
    img_not_covered=img_stat{image_i}.not_covered_signs;
    img_total=img_covered+img_part_covered+img_not_covered;
    img_total_area=img_stat{image_i}.total_area;
    fprintf(file,"%s\t",img_stat{image_i}.file_name);
    fprintf(file,"%.1f\t",(img_covered/img_total)*100); 
    fprintf(file,"%.1f\t",(img_part_covered/img_total)*100);
    fprintf(file,"%.1f\t",(img_not_covered/img_total)*100);
    fprintf(file,"%.1f\t",(img_area/img_total_area)*100);
    fprintf(file,"%.1d\t",img_total); fprintf(file,"\n");
end
if file > 2
    fclose(file);
end
end