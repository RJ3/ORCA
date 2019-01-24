function ORCA
%% ORCA (Objective Routine for Conduction velocity Analysis)
% Version 2.1
% Version 2.2 (2018-08-08) RJ3
% Version 2.3 (2019-01-16) DM
%
% Written by: Ashish Doshi and Bastiaan Boukens
% Includes snippets by: Christopher Gloschat, CVRTI - University of Utah
% Authors' Affiliation: Laboratory of Igor Efimov -The George Washington 
% University
% Author Note: Please contact ashishndoshi@gmail.com with questions or 
% suggested modifications. We welcome improvements to the code and user 
% interface! We are not experts at MATLAB, so any improvements are 
% appreciated.
% Associated Publication: 
% http://www.sciencedirect.com/science/article/pii/S0010482515001754?via%3Dihub

pause on;       % enable MATLAB's pause function (allows time for user to respond)

% Show splash screen
if exist('ORCAlogo.png','file')==2
    imshow('ORCAlogo.png','Border','tight')
    pause(2)
    close
else
end

% User prompt for input
prompt1 = {'Directory','Filename (*.csv)','cm/px','stimX (enter 0 to click)','stimY (enter 0 to click)','Edit advanced options? Y/N'};
dlg_title1 = 'User options';
num_lines1 = [1 60];
def1 = {'C:\Users\dmcculloug\Desktop\Data\MEHP\ConductionVelocity\20180522-rata\ActMaps\','ActMap-20180522-rata-10.csv','0.0048','0','0','N'};
answer = inputdlg(prompt1,dlg_title1,num_lines1,def1);
% process user inputs
direc = answer{1};
filename = answer{2};
% magnx = str2double(answer{3});
dx = str2double(answer{3});
dy=dx;
stimx=str2double(answer{4});
stimy=str2double(answer{5});
advanced = answer{6};

if strcmp(advanced,'Y') || strcmp(advanced,'y') || strcmp(advanced,'Yes') || strcmp(advanced,'yes') || strcmp(advanced,'YES')
    % User prompt for input for advanced options
    prompt2 = {'Enter number of degrees between tested angles','Enter angle offset','Enter sampling rate of interpolation line','Enter actual distance between recording sites in cm (x-direction)','Enter actual distance between recording sites in cm (y-direction)'};
    dlg_title2 = 'Advanced user options';
    num_lines2 = 1;
    def2 = {'10','5','500','0.01','0.01'};
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
    linesamplerate = 500; % length of vector used to draw line for activation times
%     dx = 0.01/magnx;    % distance between elements in x direction (cm)
%     dy = 0.01/magnx;    % distance between elements in y direction (cm)
end

% load activation map
actMap1 = csvread([direc,filename]);
[yelems, xelems] = size(actMap1);    % detect size of activation map
xnew=dx:dx:xelems*dx;    % vector of elements in x-direction
xMax = max(xnew);
ynew=dy:dy:yelems*dy;    % vector of elements in y-direction

% scale colormap of activation times to 5th and 90th percentiles to
% minimize background and noise
% ActRawBound = prctile(reshape(actMap1,numel(actMap1),1),[5 90]);
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


% scale color map of region of interest based on 1st and 80th percentile of
% activation times to minimize noise and enhance contrast for stimulus
% selection
ActBounds = prctile(reshape(ActRegion,numel(ActRegion),1),[1 80]);

% plot region and ask for stimulus point
if stimx == 0
    stim_select=0;  % set loop trigger
else
    stim_select=1;
end

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
heightCM = (height+1)*dy; % Activation map height in cm
widthCM = (width+1)*dy; % Activation map width in cm
xmin2 = xmin + round(stimx/dx-width/2);
ymin2 = ymin + round(stimy/dy-height/2);
disp(['Size W x H (pixels) : ',num2str(width),' x ',num2str(height)])
disp(['Size W x H (cm) : ',num2str(widthCM),' x ',num2str(heightCM)])
fprintf('Stim X Y: \t %f \t %f\n', stimx, stimy)

if xmin2>1 && ymin2>1 && (xmin2+width)<=xelems && (ymin2+height)<=yelems
    % if recentering region around stimulus will not go outside data bounds
    disp('Creating region of interest!')
    xregion = xmin2:1:(xmin2+width);      % rows to pull
    yregion = ymin2:1:(ymin2+height);     % columns to pull
    ActRegion = actMap1(yregion,xregion);   % new activation map (region of interest)
    disp('Chosen stim point (stimx, stimy):')
    stimx = max(xnew)/2        % redefine stim point as center of region of interest
    stimy = max(ynew)/2        % redefine stim point as center of region of interst
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

interpline_y2 = zeros(numlines,linesamplerate); % create matrix for y-coordinates of lines used to interpolate activation map data (same line as demolines but more data points)
interpline_x2 = zeros(numlines,linesamplerate); % create matrix for x-coordinates of lines used to interpolate activation map data
interpActTime2 = zeros(numlines,linesamplerate);   % matrix for activation time along interpolation line
% Calculated angles to denote region of analysis (borders at corners of activation map)
quad1_angle = atand(abs(stimy-height)/abs(stimx-width));
quad2_angle = (180-quad1_angle);
quad3_angle = quad1_angle + 180;
quad4_angle = quad2_angle + 180;

% calculate coordinates of interpolation lines from angles
for i=1:numlines
    % x-coordinates to use for interpolation line (interpline_x) calculated
    % based on width of region, stimulus site, and angle. For steep angles
    % that are greater than a certain threshold angle (i.e. once the 
    % interpolation line does not cover the entire width of the rectangle),
    % the expected range of x-coordinates are calculated from width and
    % angle
    angle = (i-1)*dangle+angle_off;
    angleRad = pi*(angle/180);
%     disp([num2str(angle),newline,...
%         'interpline_x length: ',num2str(length(interpline_x(i,:))),newline, ...
%         'interpline_y length: ',num2str(length(interpline_y(i,:)))])

    % use linear interpolation of 2D activation map; obtain activation time
    % of an interpolation line drawn along the activation map
    demolines(i,:) = xnew*tan(angleRad) - stimx*tan(angleRad) + stimy;
    if angle < 180
        if angle < 90
            firstY = demolines(i,1); % y-intercept of current interpolation line
            startX = firstY*(stimx/(firstY - stimy)); % x-intercept of current interpolation line
            endX = (heightCM - firstY)*(stimx/(stimy - firstY));
            if firstY > 0 % from 0 - ~45
                display('Quad1.5')
                interpline_x2(i,:) = xMax/linesamplerate:xMax/linesamplerate:xMax;
            else % from ~45 - 90
                display('Quad2.0')
                interpline_x2(i,:) = startX:(endX-startX)/(linesamplerate-1):endX;
            end

        else % from 90 - 180
            firstY = demolines(i,1); % y-intercept of current interpolation line
            startX = firstY*(stimx/(firstY - stimy)); % x-intercept of current interpolation line
            endX = (heightCM - firstY)*(stimx/(stimy - firstY));
            length((startX:(endX - startX)/(linesamplerate - 1):endX));
            if firstY > heightCM % from 90 - ~135
                display('Quad2.5')
                interpline_x2(i,:) = fliplr(endX:abs(startX-endX)/(linesamplerate-1):startX);
            else % from ~135 - 180 TODO plot not centered on stim line
                display('Quad3.0')
                interpline_x2(i,:) = fliplr(xMax/linesamplerate:xMax/linesamplerate:xMax);
            end
        end

    else    % greater than 180
        if angle < 270
            firstY = demolines(i,1); % y-intercept of current interpolation line
            startX = firstY*(stimx/(firstY-stimy)); % x-intercept of current interpolation line
            endX = (heightCM-firstY)*(stimx/(stimy -firstY));
            secondY = widthCM*((stimy -firstY)/stimx)+firstY;
            if secondY < heightCM % from 180 - ~225
                display('Quad3.5...')
                interpline_x2(i,:) = fliplr(xMax/linesamplerate:xMax/linesamplerate:xMax);
            else % from ~225 - 270
                display('Quad4.0...')
                interpline_x2(i,:) = fliplr(startX:abs(endX-startX)/(linesamplerate-1):endX);
            end
        else % from 270 - 360
            firstY = demolines(i,1); % y-intercept of current interpolation line
            startX = firstY*(stimx/(firstY-stimy)); % x-intercept of current interpolation line
            endX = (heightCM - firstY)*(stimx/(stimy -firstY));
            secondY = widthCM*((stimy -firstY)/stimx)+firstY;
            if firstY > heightCM % from 270 - ~315
                display('Quad4.5...')
                interpline_x2(i,:) = endX:abs(endX-startX)/(linesamplerate-1):startX;
            else % from ~315 - 360
                display('Quad1.0...')
                interpline_x2(i,:) = xMax/linesamplerate:xMax/linesamplerate:xMax;
            end
        end
    end
    interpline_y2(i,:) = interpline_x2(i,:)*tan(angleRad) - stimx*tan(angleRad) + stimy;
    interpActTime2(i,:) = interp2(xnew,ynew,ActRegion,interpline_x2(i,:),interpline_y2(i,:),'linear');
    
    display(['^^^^^^ contains Angle: ',num2str(angle),' '])
    %interpline_y(i,:) = interpline_x(i,:)*tan(pi*(((i-1)*dangle+angle_off)/180))-stimx*tan(pi*(((i-1)*dangle+angle_off)/180))+stimy;
%     interpActTime(i,:) = interp2(xnew,ynew,ActRegion,interpline_x(i,:),interpline_y(i,:),'linear');
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

% setup results vector / RJ3 2018-09-17
dxVec=repmat(dx, length(anglevec),1); % 1- column is cm/px that the user entered
stimXvec=repmat(stimx,length(anglevec),1); % 2 - stimX that user selected
stimYvec=repmat(stimy,length(anglevec),1); % 3 - stimY that user selected
results=horzcat([dxVec stimXvec stimYvec anglevec' nan(length(anglevec),1)]); % 4 - init cm/sec vector

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
            title(['File: ', filename])
            xlabel('cm'); ylabel('cm');
            axis([dx (width+1)*dx dy (height+1)*dy])
            hold on
            plot(xnew,demolines(i,:),'w','LineWidth',1) %plot interpolation line
            %plot arrow
            quiver(stimx,stimy,arrowmag*cos(pi*(((i-1)*dangle+angle_off)/180)),arrowmag*sin(pi*(((i-1)*dangle+angle_off)/180)),'r','MaxHeadSize',10,'LineWidth',2,'MarkerSize',30)
            set(gca,'Fontsize',16,'fontWeight','bold')
            hold off
            caxis([ActBounds(1) ActBounds(2)])
            
            % characterize path along which values interpolated
            curAngle = (i-1)*dangle+angle_off; % Current angle of analysis line (in degrees)
            pathlength2 = abs((max(interpline_x2(i,:))-min(interpline_x2(i,:)))./cos(pi*curAngle/180));    % calculate length of entire interpolation line
            fprintf(['Angle: ',num2str(curAngle),', pathlength: ',num2str(pathlength2)])
            dlength2 = pathlength2/linesamplerate; % calculate distance between interpolated points on path of line
            totalpathvec2 = dlength2:dlength2:pathlength2;    % vector representing total interpolation path (including path outside of region)
%             idx_first = find(sum(~isnan(interpActTime(i,:)),1) > 0, 1, 'first');    % find first point of interpolation line in the actual region of interest
%             idx_last = find(sum(~isnan(interpActTime(i,:)),1) > 0, 1, 'last');      % find last point of interpolation line in the region of interest
            
            %top-right plot: activation time along interpolation line
            ActPlot = subplot(2,2,2);
            ActCurve2 = smooth(totalpathvec2,interpActTime2(i,:),linesamplerate/10,'moving');
            
%             plot(totalpathvec,ActCurve,'color',[0.5 0.5 0.5],'Linewidth',1)
            plot(totalpathvec2,ActCurve2,'color',[0.3 0.4 0.3],'Linewidth',1)
            hold on
            plot(totalpathvec2,interpActTime2(i,:),'.','Color','r')
            % Show stim point and analysis direction on activation time
            % plot (may only work for relatively centered stim points!)
            if curAngle < 180
                if curAngle < 90
                    firstY = demolines(i,1); % y-intercept of current interpolation line
                    firstX = firstY*(stimx/(firstY-stimy)); % x-intercept of current interpolation line
                    if firstY > 0 % from 0 - ~45
                        stimLineX = pdist([ stimx,stimy ; 0,firstY ]);
                    else % from ~45 - 90
                        stimLineX = pdist([ stimx,stimy ; firstX,0 ]);
                    end
                    
                else % from 90 - 180
                    firstY = demolines(i,1); % y-intercept of current interpolation line
                    firstX = firstY*(stimx/(firstY-stimy)); % x-intercept of current interpolation line
                    secondX = (heightCM-firstY)*(stimx/(stimy -firstY));
                    secondY = widthCM*((stimy -firstY)/stimx)+firstY;
                    if firstY > heightCM % from 90 - ~135
                        stimLineX = pdist([ stimx,stimy ; firstX,0 ]);
                    else % from ~135 - 180 TODO plot not centered on stim line
                        stimLineX = pdist([ stimx,stimy ; firstX,firstY ]);
                    end
                end
                
            else    % greater than 180
                if curAngle < 270
                    firstY = demolines(i,1); % y-intercept of current interpolation line
                    secondX = (heightCM-firstY)*(stimx/(stimy -firstY));
                    secondY = widthCM*((stimy -firstY)/stimx)+firstY;
                    if secondY < heightCM % from 180 - ~225
                        stimLineX = pdist([ stimx,stimy ; widthCM,secondY ]);
                    else % from ~225 - 270
                        stimLineX = pdist([ stimx,stimy ; secondX,heightCM ]);
                    end
                else % from 270 - 360
                    firstY = demolines(i,1); % y-intercept of current interpolation line
                    secondX = (heightCM-firstY)*(stimx/(stimy -firstY));
                    secondY = widthCM*((stimy -firstY)/stimx)+firstY;
                    if firstY > heightCM % from 270 - ~315
                        stimLineX = pdist([ stimx,stimy ; secondX,heightCM ]);
                    else % from ~315 - 360
                        stimLineX = pdist([ stimx,stimy ; 0,firstY ]);
                    end
                end
                %disp(['SecondX: ',num2str(secondX),' | SecondY: ',num2str(secondY)])
            end
            %disp(['FirstX: ',num2str(firstX),' | FirstY: ',num2str(firstY)])
            disp(['stimLineX: ',num2str(stimLineX)])
            plot([0 pathlength2], [ActBounds(1)/2 ActBounds(1)/2], '--','Color','w') % Line to show bounds of data (ends of analysis line including NANs)
            plot([stimLineX stimLineX], [0 ActBounds(1)], '--','Color','w') % Line to mark stim point along analysis line
            drawArrow = @(x,y,varargin) quiver( x(1),y(1),x(2)-x(1),y(2)-y(1),0, varargin{:}); % Arrow to show analysis direction
            arrowX = [stimLineX stimLineX+0.2];
            arrowY = [ActBounds(1)/2 ActBounds(1)/2];
            drawArrow(arrowX,arrowY,'r','MaxHeadSize',6,'LineWidth',1,'MarkerSize',4);
            hold off
            ylim([ActBounds(1)/3 ActBounds(2)+2])
            yticks(round(ActBounds(1)/3) : 2 : round(ActBounds(2)+2))
            xlim([0 sqrt(max(xnew)^2 + max(ynew)^2)])  % Set x-axis limit to max length of any/all analysis lines
            xticks(0 : 0.5 : round(sqrt(max(xnew)^2 + max(ynew)^2)))
            %xlim([totalpathvec(idx_first) totalpathvec(idx_last)])
            title('Activation times along line')
            ylabel('Activation time (msec)')
            xlabel('Distance along analysis line (cm)')
            set(gca,'Fontsize',16,'fontWeight','bold')
            whitebg([0 0 0])
            
            %bottom-right plot: plot CV vs angle
            if sum(CVperangle)~=0
                CVPlot = subplot(2,2,4);
                   bar(anglevec,CVperangle,'b')
                xlim([anglevec(1) anglevec(end)])
                title('User-measured CV at each angle')
                ylabel('Conduction velocity (cm/sec)')
                xlabel('Angle')
                set(gca,'Fontsize',16,'fontWeight','bold')
                whitebg([0 0 0])
                
                % 2018-09-10 New Table Section for Results
                results(:,5)=CVperangle'
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
            [~, idx1] = min(abs(xselect(1)-totalpathvec2));
            [~, idx2] = min(abs(xselect(2)-totalpathvec2));
            x1 = totalpathvec2(idx1);
            x2 = totalpathvec2(idx2);
            Act1 = interpActTime2(i,idx1);
            Act2 = interpActTime2(i,idx2);
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
