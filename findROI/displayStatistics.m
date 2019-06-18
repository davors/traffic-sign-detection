function displayStatistics(statistics)
    filter=statistics.total_signs>0;
    
    fprintf("All\n")
    fprintf("Category\t\t\t"); fprintf("%-6d\t",find(filter(1:end-1))); fprintf("All\n");
    fprintf("Covered \t\t\t"); fprintf("%.1f%%\t",(statistics.covered_signs(filter)./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Partially covered\t"); fprintf("%.1f%%\t",(statistics.partially_covered_signs(filter)./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Not covered\t\t\t"); fprintf("%.1f%%\t",((statistics.total_signs(filter)-statistics.partially_covered_signs(filter)-statistics.covered_signs(filter))./statistics.total_signs(filter))*100); fprintf("\n");
    fprintf("Covered area\t\t"); fprintf("%.1f%%\t",(statistics.covered_area(filter)./statistics.total_area(filter))*100); fprintf("\n");
    %fprintf("Total area\t\t\t"); fprintf("%d\t",statistics.total_area(filter)); fprintf("\n");
    fprintf("Total signs\t\t\t"); fprintf("%-6d\t",statistics.total_signs(filter)); fprintf("\n");
    
end