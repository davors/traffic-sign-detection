function displayStatistics(statistics,showByCategory)

if ~exist('showByCategory','var') || isempty(showByCategory)
    showByCategory = 1;
end

if showByCategory
    filter=statistics.total_signs>0;    
    fprintf("All\n")
    fprintf("Category\t\t\t"); fprintf("%-6d\t",find(filter(1:end-1))); fprintf("All\n");
    fprintf("Covered \t\t\t"); fprintf("%.2f%%\t",(statistics.covered_signs(filter)./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Partially covered\t"); fprintf("%.2f%%\t",(statistics.partially_covered_signs(filter)./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Not covered\t\t\t"); fprintf("%.2f%%\t",((statistics.total_signs(filter)-statistics.partially_covered_signs(filter)-statistics.covered_signs(filter))./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Covered area\t\t"); fprintf("%.2f%%\t",(statistics.covered_area(filter)./statistics.total_area(filter))*100); fprintf("\n");
    %fprintf("Total area\t\t\t"); fprintf("%d\t",statistics.total_area(filter)); fprintf("\n");
    fprintf("Total signs\t\t\t"); fprintf("%-6d\t",statistics.total_signs(filter)); fprintf("\n");

else
    % Display only aggregated statistics
    fprintf("Covered \t\t\t"); fprintf("%.2f%%\t",(statistics.covered_signs(end)./statistics.total_signs(end))*100); fprintf("\n");
    fprintf("Partially covered\t"); fprintf("%.2f%%\t",(statistics.partially_covered_signs(end)./statistics.total_signs(end))*100); fprintf("\n");
    fprintf("Not covered\t\t\t"); fprintf("%.2f%%\t",((statistics.total_signs(end)-statistics.partially_covered_signs(end)-statistics.covered_signs(end))./statistics.total_signs(end))*100); fprintf("\n");
    fprintf("Covered area\t\t"); fprintf("%.2f%%\t",(statistics.covered_area(end)./statistics.total_area(end))*100); fprintf("\n");
    fprintf("Total signs\t\t\t"); fprintf("%-6d\t",statistics.total_signs(end)); fprintf("\n");
    
end
