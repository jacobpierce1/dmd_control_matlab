%(* ::Package:: *)



% %%%%%%%%%%%%%%%%%%% NEW FUNCTIONS %%%%%%%%%%%%%%%%%%%

function LichtCrafterTest ()
  
    L=LightCrafter();
    L.tcpConnection = tcpip('192.168.1.100',21845);
    fopen(L.tcpConnection);
    pause(2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % do something
    data = make_washer(300, 300, 0, 100);
    L.setBMPImage(data, L.tcpConnection);
    
%     
%     L.setDisplayMode('04', L.tcpConnection)
%     L.setPatternSequence(int2str(1), '2', '0', '01', '0', '1E8480', '249F0', '01', L.tcpConnection)

%     L.displayPattern('01')
%     L.SSPatternSequence('01', L.tcpConnection)


    % move_circle (L, 100, 100, 300, 300, 20, 30)
        % set parameters for the pattern

    pause(1)
    L.setDisplayMode('04', L.tcpConnection)
    L.SSPatternSequence('00', L.tcpConnection)
    
    num_patterns = 2;
    L.setPatternSequence('1', '2', '0', '01', '0', dec2hex(100000), dec2hex(20000), '1', L.tcpConnection)
    x1 = 100;
    y1 = 100;
    x2 = 300;
    y2 = 300;
    r = 20;
    
%     num_patterns = num_patterns - 1;
%     for i = 0:num_patterns
%         x = round(x1*(num_patterns-i)/num_patterns + x2*i/num_patterns);
%         y = round(y1*(num_patterns-i)/num_patterns + y2*i/num_patterns);
%         washer_data = make_washer(x, y, 0, r);
%         disp(int2str(i))
%         L.setPattern(int2str(i), washer_data, L.tcpConnection)
%         
%     end
    
    L.setPattern('00', load_image_data('test_1bitdepth.bmp'), L.tcpConnection)
    L.setPattern('01', load_image_data('test_2bitdepth.bmp'), L.tcpConnection)
    % L.setPattern('02', load_image_data('test_3bitdepth.bmp'), L.tcpConnection)

    
    L.SSPatternSequence('01', L.tcpConnection)

%     L.SSPatternSequence('01', L.tcpConnection)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % close the lightcrafter 
    pause(2);
    fclose(L.tcpConnection);
    % pause(2);
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     no_im = load_image_data ('no_image.bmp');
%     im2 = load_image_data('im2.bmp');
%     im20 = load_image_data('im20.bmp');
%     washer = make_washer(300, 300, 20, 50);
%     single_pixel_data = single_pixel(300, 300);
%     L.setBMPImage(single_pixel_data, L.tcpConnection)
% 

%     num_ims = 96;
%     for 
%     
    
%  make_images()    

end


function reset_dmd()
    clear('L')
end

function make_images()    
    test_1bitdepth = zeros( 684, 608,1);
    test_1bitdepth (300:380, 300:380,:) = 255;
    imwrite( test_1bitdepth, 'test_1bitdepth.bmp' );
    
    test_2bitdepth = zeros( 684, 608);
    test_2bitdepth (200:280, 200:280) = 255;
    imwrite( test_2bitdepth, 'test_2bitdepth.bmp' );
        
    test_3bitdepth = zeros( 684, 608);
    test_3bitdepth (400:480, 400:480) = 255;
    imwrite( test_3bitdepth, 'test_3bitdepth.bmp' );

    im1 = zeros( 684, 608, 3 );
    im1 (300:380, 300:380, :) = 255;
    imwrite( im1, 'im1.bmp' );
    
    im2 = zeros( 684, 608, 1 );
    im2 (300:380, 300:380, :) = 255;
    imwrite( im2, 'im2.bmp' );
    
    im20 = zeros( 684, 608, 1 );
    im20(200:280, 200:280, :) = 255;
    imwrite( im20, 'im20.bmp' );
    
    im30 = zeros( 684, 608, 1 );
    im30(200:280, 200:280, :) = 255;
    imwrite( im30, 'im30.bmp' );

    im3 = zeros( 684, 608, 3 );
    im3 (300:380, 300:380, :) = 1;
    imwrite( im3, 'im3.bmp' );

    im4 = zeros( 684, 608, 3);
    im4 (200:280, 200:280, :) = 1;
    imwrite( im4, 'im4.bmp' );

    noim = zeros( 684, 608, 3 );
    imwrite( noim, 'no_image.bmp' );
end


% load a bmp image
function im_data = load_image_data (file_name)
    imFile = fopen(file_name); 
    im_data = fread( imFile, inf, 'uchar' );
    fclose(imFile );
end


% this function makes data for a washer and writes it to a file, and
% returns the data
function washer_data_bmp = make_washer (x, y, r1, r2, file_name)

    aspect = (480.0 / 854) * (608/684) ;
    % aspect = 1/4
    % get washer data
    washer_data = zeros(684, 608, 1);
    for i=1:684
       for j=1:608
           dsquared = aspect^2 * (i-y)^2 + (j-x)^2;
           if (dsquared <= r2^2 && dsquared >= r1^2) washer_data(i,j,:) = 1; end;
       end
    end
    
    % write to bmp, extract, and return
    if (~exist('file_name'))  file_name = 'tmp.bmp';
    else file_name = strcat(file_name, '.bmp'); end;
    
    imwrite(washer_data, file_name);
    tmp_file = fopen(file_name);
    
    washer_data_bmp = fread(tmp_file, inf, 'uchar');
    fclose(tmp_file);
end

function circle_array_bmp = make_circle_array(r, d, brightness, col, invert)

    aspect = (480.0 / 854) * (608/684) ;

    xmax = 608;
    ymax = 684;

     if(2*r > d)
       disp "ERROR: you need to pick r: 2*r < d"
       circle_array_bmp = 0;
       return
    end

    % make array of circles
    num_circs_y = floor(ymax/d);
    num_circs_x = floor(xmax*aspect/d);
    xcenters = (1:num_circs_x) * ceil(d/aspect);
    ycenters = (1:num_circs_y) * d;
        
    data = zeros(684, 608, 3);
    
    for i = 1:num_circs_y
       for j=1:num_circs_x
           
           possible_x = (xcenters(j) - 2*r):(xcenters(j) + 2*r);
           possible_y = (ycenters(i) - 2*r):(ycenters(i) + 2*r);
           
           for x = possible_x
               for y = possible_y
                   dsqu = aspect^2 * (x-xcenters(j))^2 + (y-ycenters(i))^2; 
                   if(dsqu <= r^2) data(x,y,col) = 255; end;     
               end
           end  
        end
    end
    
    if(invert) data(:,:,col) = 255-data(:,:,col); end;
        
    % write to bmp, extract, and return
    data = imadjust(data, [0 1], [0 brightness]);
    imwrite(data, 'tmp.bmp');
    tmp_file = fopen('tmp.bmp');
    circle_array_bmp = fread(tmp_file, inf, 'uchar');
    % circle_array_bmp = circle_array_bmp / 5;
    % circle_array_bmp = imadjust(circle_array_bmp, )
    fclose(tmp_file); 

%       [tmp, map] = imread('tmp.bmp');
%         circle_array_bmp = ind2rgb(tmp, map);
end



function data_bmp = single_pixel(x, y)
    data = zeros(684, 608, 3);
    data (x,y,:) = 1;
    imwrite(data, 'tmp.bmp');
    tmp_file = fopen('tmp.bmp');
    data_bmp = fread(tmp_file, inf, 'uchar');
    fclose(tmp_file);
end



function move_circle (L, x1, y1, x2, y2, r, time)
    
    % set parameters for the pattern
    L.setDisplayMode('04', L.tcpConnection)
    L.setPatternSequence('1', '96', '0', '01', '0', '1E8480', '249F0', '2', L.tcpConnection)

    for i = 1:96
        x = round(x1*(96-i)/96 + x2*i/96)
        y = round(y1*(96-i)/96 + y2*i/96)
        washer_data = make_washer(x, y, 0, r);
        L.setPattern(int2str(i), washer_data, L.tcpConnection)
%     L.setPattern('00', im2, L.tcpConnection)
%     L.setPattern('01', im20, L.tcpConnection)
%     L.displayPattern('01')
%     num_ims = 96;
%     for 
    end
    
    L.SSPatternSequence('01', L.tcpConnection)
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   
    
% serial = [3 1 1 0 0 0 5 3 1 5];
% delete(L)
% delete(tcpObject)
% use clear instead

% create simple image


% load file




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% L.setStaticColor( 'FF', 'FF', 'FF', tcpObject )
% L.setPattern('0A', tcpObject)

% L.getVersion( '00', tcpObject)
% data = fread(tcpObject,tcpObject.BytesAvailable);
% disp(data)

% L.setPatternSequence('1', '2', '0', '0', '5', '5', '5000', '0', tcpObject)
% L.setPattern('00', imData3, tcpObject)
% L.setPattern('01', imData4, tcpObject)
% L.setDisplayMode('04', tcpObject)
% L.SSPatternSequence('00', tcpObject)

% while 1
%     L.setBMPImage(imData3, tcpObject)
%     pause(5)
%     L.setBMPImage(noimData, tcpObject)
%     pause(5)
% end
