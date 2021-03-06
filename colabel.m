%%
[filename,pathname,filterindex] = uigetfile('../*.tif', 'Select image file');
file_cat = strcat(pathname,filename);

I_Cfos = imread(file_cat);
I_Cfos_bw = mat2gray(I_Cfos);
Cfos_mask = mexican_hat(I_Cfos,80,4,3);
I_Cfos_equalized = adapthisteq(I_Cfos_bw,'ClipLimit',.2);


%%
[filename,pathname,filterindex] = uigetfile('../*.tif', 'Select image file');
file_cat = strcat(pathname,filename);

I_Tdt = imread(file_cat);
I_Tdt_bw = mat2gray(I_Tdt);
Tdt_mask = mexican_hat(I_Tdt,80,4,3);
I_Tdt_equalized = adapthisteq(I_Tdt_bw,'ClipLimit',.2);

%%
% multiply binary images after mexican_hat
Product = Cfos_mask .* Tdt_mask;

figure;imshow(Product);title('after multiplication')


[Colabel_L,n] = bwlabel(Product);
Colabel_Candidate_properties = regionprops(Colabel_L,'Area', 'PixelIdxList', 'Centroid');


%% first filter by size
% 
for i = 1:n
     if Colabel_Candidate_properties(i).Area < 50                
        Colabel_L(Colabel_Candidate_properties(i).PixelIdxList) = 0;
    end 
end
figure;imshow(Colabel_L);title('filter by area');

[Colabel_L,n] = bwlabel(Colabel_L);
Colabel_Candidate_properties = regionprops(Colabel_L, 'PixelIdxList', 'Centroid');


%% second filter by centroid, 





%% output label, and visualize on the image to see how they spread 




