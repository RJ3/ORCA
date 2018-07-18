function ORCA2_2
%% ORCA (Objective Routine for Conduction velocity Analysis)
% Version 2.1

% Created by Ashish Doshi and Bastiaan Boukens
% Laboratory of Igor Efimov
% Washington University in St. Louis
% Please contact ashishndoshi@gmail.com with questions or suggested
% modifications. We welcome improvements to the code and user interface!
% We are not experts at MATLAB, so any improvements are appreciated.

pause on;       % enable MATLAB's pause function (allows time for user to respond)

% Show splash screen
if exist('ORCAlogo.png','file')==2
    imshow('ORCAlogo.png','Border','tight')
    pause(2)
    close
else
end

% User prompt for input
prompt1 = {'Path','Filename','Enter magnifaction power (for example, 0.9)','Edit advanced options? Y/N'};
dlg_title1 = 'User options';
num_lines1 = 1;
def1 = {'/home/lab/Documents/Langendorff-MEHP/ActMaps/','ActMap.csv','1','Y'};
answer = inputdlg(prompt1,dlg_title1,num_lines1,def1);
% process user inputs
direc = answer{1};
filename = answer{2};
magnx = str2double(answer{3});
advanced = answer{4};

if strcmp(advanced,'Y') || strcmp(advanced,'y') || strcmp(advanced,'Yes') || strcmp(advanced,'yes') || strcmp(advanced,'YES')
    % User prompt for input for advanced options
    prompt2 = {'Enter number of degrees between tested angles','Enter angle offset','Enter sampling rate of interpolation line','Enter actual distance between recording sites in cm (x-direction)','Enter actual distance between recording sites in cm (y-direction)'};
    dlg_title2 = 'Advanced user options';
    num_lines2 = 1;
    def2 = {'10','5','100','0.01','0.01'};
    answer = inputdlg(prompt2,dlg_title2,num_lines2,def2);
    % process user inputs
    dangle = str2double(answer{1});
    angle_off = str2double(answer{2});
    linesamplerate = str2double(answer{3});
    dx = str2double(answer{4});
    dy = str2double(answer{5});
else
    % default values if user chooses no to advanced options
    dangle = 10;     % angle in degrees between lines
    angle_off = 5;  % angle offset from 0 (to avoid artifact at 90 degrees)
    linesamplerate = 100; % length of vector used to draw line for activation times
    dx = 0.01/magnx;    % distance between elements in x direction (cm)
    dy = 0.01/magnx;    % distance between elements in y direction (cm)
end

% load activation map
actMap1 = csvread([direc,filename]);
[yelems, xelems] = size(actMap1);    % detect size of activation map
xnew=dx:dx:xelems*dx;    % vector of elements in x-direction
ynew=dy:dy:yelems*dy;    % vector of elements in y-direction

% scale colormap of activation times to 5th and 80th percentiles to
% minimize background and noise
ActRawBound = prctile(reshape(actMap1,numel(actMap1),1),[5 80]);

% plot activation map to select region of interest
% SECTION REMOVED RJ3 2018-03-15
% reg_select=0;       % set loop trigger
% figure;
% while reg_select==0     % loop until region selected
%     pcolor(xorig,yorig,actMap1)     % plot raw activation map
%     axis([0 xelems*dx 0 yelems*dy])
%     shading flat
%     colormap jet
%     caxis([ActRawBound(1) ActRawBound(2)])  % scale colormap
%     set(gca,'Fontsize',14,'fontWeight','bold')
%     whitebg([0 0 0])
%     title('Please select region of interest')
%     xlabel('cm'); ylabel('cm');
%     rect = getrect;             % retrieve user input
%     xmin = round(rect(1)/dx);
%     ymin = round(rect(2)/dy);
%     width = round(rect(3)/dx);
%     height = round(rect(4)/dy);
%     % cases for improper user selection
%     if (xmin < 1) || (ymin < 1) || (xmin+width > length(xorig)) || (ymin+height > length(yorig))
%         msgbox('Please limit your selection to the grid','Error','error','modal');
%      elseif (height == 0) || (width == 0)
%         msgbox('Please click and drag to select an area','Error','error','modal');
%     else
%         reg_select=1;       % user selected properly
%     end
% end

ActRegion = actMap1;   % new activation map (region of interest)

% NEW 2018-03-15 RJ3
% ActRegion = actMap1;
% xnew = xorig;
% ynew = yorig;


% scale color map of region of interest based on 1st and 95th percentile of
% activation times to minimize noise and enhance contrast for stimulus
% selection
ActBounds = prctile(reshape(ActRegion,numel(ActRegion),1),[1 95]);

% plot region and ask for stimulus point
stim_select=0;  % set loop trigger

while stim_select==0
    pcolor(xnew,ynew,ActRegion)
    shading flat
    colormap jet
    caxis([ActBounds(1) ActBounds(2)])
    whitebg([0 0 0])
    set(gca,'Fontsize',14,'fontWeight','bold')
    title('Please select stimulus point and press enter')
    xlabel('cm'); ylabel('cm');
    [stimx, stimy] = getpts;     % retrieve user input
    disp(stimx) % added live feedback
    disp(stimy)
    % cases of improper user selection
    if length(stimx)>1
        msgbox('Please select only one point','Error','error','modal');
    elseif length(stimx)<1
        msgbox('Please select one point','Error','error','modal'); 
    else
        stim_select=1;  % user selected properly
    end
end

% You can override the stimulus point here.
%   stimx=0.12779;
%   stimy=0.024192;

% center region of interest around stimulus point
xmin = 1;
ymin = 1;
[height, width] = size (actMap1);

xmin2 = xmin + round(stimx/dx-width/2);
ymin2 = ymin + round(stimy/dy-height/2);

if xmin2>1 && ymin2>1 && (xmin2+width)<=xelems && (ymin2+height)<=yelems
    % if recentering region around stimulus will not go outside data bounds
    xregion = xmin2:1:(xmin2+width);      % rows to pull
    yregion = ymin2:1:(ymin2+height);     % columns to pull
    ActRegion = actMap1(yregion,xregion);   % new activation map (region of interest)
    stimx = max(xnew)/2;        % redefine stim point as center of region of interest
    stimy = max(ynew)/2;        % redefine stim point as center of region of interst
else
%     % if recentering region will go outside of data bounds, clip the region
%     % of interest to keep it within the data bounds while keeping the
%     % stimulus at the center (important for calculation of the threshold
%     % angle later)
%     if xmin2<1
%         xmin2=1;
%         width=2*((xmin+stimx/dx)-xmin2);
%     end
%     if ymin2<1
%         ymin2=1;
%         height=2*((ymin+stimy/dy)-ymin2);
%     end
%     if (xmin2+width)>xelems
%         width=2*(xelems-(xmin+stimx/dx));
%         xmin2=round(xmin+stimx/dx-width/2);
%     end
%     if (ymin2+height)>yelems
%         height=2*(yelems-(ymin+stimy/dy));
%         ymin2=round(ymin+stimy/dy-height/2);
%     end
%     xregion = xmin2:1:(xmin2+width);      % rows to pull
%     yregion = ymin2:1:(ymin2+height);     % columns to pull
%     ActRegion = actMap1(yregion,xregion);   % new activation map (region of interest)
%     xnew = dx:dx:(width+1)*dx;                 %  x-coordinates of new activation map
%     ynew = dy:dy:(height+1)*dy;                %  y-coordinates of new activation map
%     stimx = max(xnew)/2;        % redefine stim point as center of region of interest
%     stimy = max(ynew)/2;        % redefine stim point as center of region of interst
end

close all

% define lines passing through stimulus point at several angles
numlines = 360/dangle;  % number of lines to draw
demolines = zeros(numlines,length(xnew)); % create matrix for y-coordinates of lines to be drawn on activation map
interpline_y = zeros(numlines,linesamplerate); % create matrix for y-coordinates of lines used to interpolate activation map data (same line as demolines but more data points)
interpline_x = zeros(numlines,linesamplerate); % create matrix for x-coordinates of lines used to interpolate activation map data
interpActTime = zeros(numlines,linesamplerate);   % matrix for activation time along interpolation line

% calculate coordinates of interpolation lines from angles
for i=1:numlines
    % x-coordinates to use for interpolation line (interpline_x) calculated
    % based on width of region, stimulus site, and angle. For steep angles
    % that are greater than a certain threshold angle (i.e. once the 
    % interpolation line does not cover the entire width of the rectangle),
    % the expected range of x-coordinates are calculated from width and
    % angle
    
    if (i-1)*dangle+angle_off < 90      % for angles less than 90 degrees
        if (pi*(((i-1)*dangle+angle_off)/180)) > atan(height/(0.9*width))       % for angles greater than threshold (0.9 factor of width is fudge factor)
            % x-coordinates calculated based on steepness of angle
            interpline_x(i,:) = (max(xnew)-stimx-(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/2):(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate:(max(xnew)-stimx+(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/2)-(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate;
        else   % for shallow angles less than threshold
            % x-coordinates taken as x-coordinates of entire region
            interpline_x(i,:) = max(xnew)/linesamplerate:max(xnew)/linesamplerate:max(xnew);
        end
        
    elseif (i-1)*dangle+angle_off > 90  && (i-1)*dangle+angle_off <= 180  % for angles between 90 and 180 degrees
        if (pi*(((i-1)*dangle+angle_off)/180)) < pi - atan(height/(0.9*width))  % for angles between 90 degrees and threshold (steep angles)
            % x-coordinates calculated based on steepness of angle
            interpline_x(i,:) = fliplr((max(xnew)-stimx-(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/2):(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate:(max(xnew)-stimx+(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/2)-(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate);
        else   % for shallow angles less than threshold
            % x-coordinates taken as x-coordinates of entire region
            interpline_x(i,:) = fliplr(max(xnew)/linesamplerate:max(xnew)/linesamplerate:max(xnew));
        end
        
    elseif (i-1)*dangle+angle_off > 180  && (i-1)*dangle+angle_off < 270  % for angles between 180 and 270 degrees
        if (pi*(((i-1)*dangle+angle_off)/180)) > pi + atan(height/(0.9*width))  % for angles between 270 degrees and threshold (steep angles)
            % x-coordinates calculated based on steepness of angle
            interpline_x(i,:) = fliplr((max(xnew)-stimx-(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/2):(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate:(max(xnew)-stimx+(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/2)-(max(ynew)./tan(pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate);
        else   % for shallow angles less than threshold
            % x-coordinates taken as x-coordinates of entire region
            interpline_x(i,:) = fliplr(max(xnew)/linesamplerate:max(xnew)/linesamplerate:max(xnew));
        end
        
    elseif (i-1)*dangle+angle_off > 270  % for angles greater than 270 degrees
        if (pi*(((i-1)*dangle+angle_off)/180)) < 2*pi - atan(height/(0.9*width))  % for angles between 270 degrees and threshold (i.e. steep angles)
            % x-coordinates calculated based on steepness of angle
            interpline_x(i,:) = (max(xnew)-stimx-(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/2):(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate:(max(xnew)-stimx+(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/2)-(max(ynew)./tan(pi-pi*(((i-1)*dangle+angle_off)/180)))/linesamplerate;
        else   % for shallow angles (i.e. between threshold and 180 degrees)
            % x-coordinates taken as x-coordinates of entire region
            interpline_x(i,:) = max(xnew)/linesamplerate:max(xnew)/linesamplerate:max(xnew);
        end
        
    elseif ((i-1)*dangle+angle_off == 90)||((i-1)*dangle+angle_off == 270)         % if angle is exactly 90 or 270 degrees
        % abort
        error('Routine unable to run interpolation at exactly 90 or 270 degrees. Please re-run the routine and choose angle options that do not result in an interpolation line at 90 degrees.');
    end
    % use linear interpolation of 2D activation map; obtain activation time
    % of an interpolation line drawn along the activation map
    demolines(i,:) = xnew*tan(pi*(((i-1)*dangle+angle_off)/180))-stimx*tan(pi*(((i-1)*dangle+angle_off)/180))+stimy;
    interpline_y(i,:) = interpline_x(i,:)*tan(pi*(((i-1)*dangle+angle_off)/180))-stimx*tan(pi*(((i-1)*dangle+angle_off)/180))+stimy;
    interpActTime(i,:) = interp2(xnew,ynew,ActRegion,interpline_x(i,:),interpline_y(i,:),'linear');
    % define magnitude of display arrow from size of region
    arrowmag = min(size(ActRegion))/400;
end

% set up main figure
h_fig = figure;
set(gcf,'Position',[100 100 1200 800])

% initialize loop variables
i = 0;                      % current line number
trigger_main = 1;           % subroutine to run based on user command
arrowkey = 'rightarrow';    % user keyboard command
% (first run through loop plots data for first interpolation line)

% set up CV vector
CVperangle = zeros(1,numlines);
anglevec = angle_off+dangle*(0:(numlines-1));

 while trigger_main > 0
    % wait for keyboard command and jump to corresponding switch case
    set(h_fig,'KeyPressFcn',@(H,E) assignin('caller','arrowkey',E.Key));
     pause(0.1);
    if strcmp(arrowkey,'rightarrow')
        trigger_main = 2;
    elseif strcmp(arrowkey,'leftarrow')
        trigger_main = 3;
    elseif strcmp(arrowkey,'space')
        trigger_main = 4;
    elseif strcmp(arrowkey,'escape')
        close all
        break
    else
        trigger_main = 1;
    end
    
    % user presses right or left arrow key: change line number and plot
    switch trigger_main
        case {2, 3}
            switch trigger_main
                case 2                  % right arrow key
                    i = i + 1;
                    if i > numlines     % if at last line
                        i = numlines;   % stay at last line
                        
                    end
                case 3                  % left arrow key
                    i = i - 1;
                    if i < 1            % if at first line
                        i = 1;          % stay at first line
                    end
            end
         
            %top-left plot: activation map with line and arrow indicating direction along which data are interpolated
            ActMap = subplot(2,2,1);
            pcolor(xnew,ynew,ActRegion) %plot activation map
            shading flat
            colormap jet
            title('Activation Map of Region')
            xlabel('cm'); ylabel('cm');
            axis([dx (width+1)*dx dy (height+1)*dy])
            hold on
            plot(xnew,demolines(i,:),'r','LineWidth',1) %plot interpolation line
            %plot arrow
            quiver(stimx,stimy,arrowmag*cos(pi*(((i-1)*dangle+angle_off)/180)),arrowmag*sin(pi*(((i-1)*dangle+angle_off)/180)),'r','MaxHeadSize',10,'LineWidth',2,'MarkerSize',30)
            set(gca,'Fontsize',16,'fontWeight','bold')
            hold off
            caxis([ActBounds(1) ActBounds(2)])
            
            % characterize path along which values interpolated
            pathlength = abs((max(interpline_x(i,:))-min(interpline_x(i,:)))./cos(pi*((i-1)*dangle+angle_off)/180));    % calculate length of entire interpolation line
            dlength = pathlength/linesamplerate; % calculate distance between interpolated points on path of line
            totalpathvec = dlength:dlength:pathlength;    % vector representing total interpolation path (including path outside of region)
            idx_first = find(sum(~isnan(interpActTime(i,:)),1) > 0, 1, 'first');    % find first point of interpolation line in the actual region of interest
            idx_last = find(sum(~isnan(interpActTime(i,:)),1) > 0, 1, 'last');      % find last point of interpolation line in the region of interest
            
            %top-right plot: activation time along interpolation line
            ActPlot = subplot(2,2,2);
            ActCurve = smooth(totalpathvec,interpActTime(i,:),linesamplerate/10,'moving');
            plot(totalpathvec,ActCurve,'color',[0.5 0.5 0.5],'Linewidth',1)
            hold on
            plot(totalpathvec,interpActTime(i,:),'.','Color','r')
            hold off
            ylim([ActBounds(1)-2 ActBounds(2)])
%            xlim([totalpathvec(idx_first) totalpathvec(idx_last)])
            title('Activation times along line')
            ylabel('Activation time (msec)')
            xlabel('Distance along analysis line (cm)')
            set(gca,'Fontsize',16,'fontWeight','bold')
            whitebg([0 0 0])
            
            %bottom-right plot: plot CV vs angle
            if sum(CVperangle)~=0;
                CVPlot = subplot(2,2,4);
                bar(anglevec,CVperangle,'b')
                xlim([anglevec(1) anglevec(end)])
                title('User-measured CV at each angle')
                ylabel('Conduction velocity (cm/sec)')
                xlabel('Angle')
                set(gca,'Fontsize',16,'fontWeight','bold')
                whitebg([0 0 0])
            end
            
            %bottom left: display UI information
            delete(findall(gcf,'Tag','instruct_box'));
            user_instruct_text = {['Current angle: ' num2str((i-1)*dangle+angle_off) ' degrees'];
                strcat(char(183),' Press the right arrow key to advance to next angle');
                strcat(char(183),' Press the left arrow key to go to the previous angle');
                strcat(char(183),' Press the space bar to measure CV between two points');
                strcat(char(183),' Press escape to quit the application')};
            annotation('textbox',[0.05,0.09,0.45,0.35],'String',user_instruct_text,'Fontsize',16,'fontweight','bold','color','w','linestyle','none','Tag','instruct_box');
            
            trigger_main = 1;
            arrowkey = 0;
            
        case 4
            point_select=0;  % set loop trigger
            axes(ActPlot);
            msgbox('Please click on two points in the activation time plot (top-right) and press enter','','help','modal');
            while point_select==0
                [xselect, yselect] = getpts;     % retrieve user input
                if length(xselect)>2
                    h = msgbox('Please select only two points','Error','error','modal'); % case of improper user selection (not enough points)
                elseif length(xselect)<2
                    h = msgbox('Please select two points','Error','error','modal'); % case of improper user selection (too many points)
                elseif xselect(1)<0 || xselect(2) <0
                    h = msgbox('Please limit your selections to points on the activation time plot (upper-right plot)','Error','error','modal');
                else
                    point_select=1;  % user selected properly
                end
            end
            [~, idx1] = min(abs(xselect(1)-totalpathvec));
            [~, idx2] = min(abs(xselect(2)-totalpathvec));
            x1 = totalpathvec(idx1);
            x2 = totalpathvec(idx2);
            Act1 = interpActTime(i,idx1);
            Act2 = interpActTime(i,idx2);
            CVuser = abs(1000*(x2-x1)/(Act2-Act1));
            CVperangle(i) = CVuser;
            delete(findall(gcf,'Tag','select_box'));
            select_info = {['Distance between points chosen: ' num2str(abs(x2-x1)) ' cm'];
                ['Difference in activation time between points: ' num2str(abs(Act2-Act1)) ' msec'];
                ['Conduction velocity between points: ' num2str(CVuser) ' cm/sec'];
                '';
                'To measure CV between two other points, press space bar again';
                'The last CV measured will be recorded as the CV for this angle';
                'To save CV and clear blue lines, go to next or previous angle'};
            annotation('textbox',[0.05,0.09,0.45,0.15],'String',select_info,'Fontsize',16,'fontweight','bold','Tag','select_box','linestyle','none','color','w');
            
            % plot line on activation map plot
            axes(ActPlot);
            hold on
            userplot = plot([x1 x2],[Act1 Act2],'b');
            hold off
            
            trigger_main = 1;
            arrowkey = 0;

    end
    
 end