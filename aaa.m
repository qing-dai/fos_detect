figure;
imshow(BW_patch(3).image);

figure;
imshow(L);
hold on;
hold on
plot(48.0465,1.1962e+03,'r*')
plot(61.7394,1.1483e+03, 'g*')
plot(46.9205,1.1420e+03, 'b*')

%find the starting point for boundary tracing
centroid = [61.7394,1.1483e+03]
col = round(dim(2)/2)-90;
row = min(find(BW(:,col)))
