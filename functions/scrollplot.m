% Plot with scrollbar to inspect time series more closely.
%
% Examples:
%   scrollplot({x,y,'color','k'},{'X'})  % horizontal scroll
%   scrollplot({x,y,'color','k'},{'Y'})  % vertical scroll
%   scrollplot({sig_t,sig_filt,'color','#0072BD'},{RR_t,sig_filt(Rpeaks),'.','MarkerSize',10,'color','#D95319'}, {'X'},{''},.2);
%
% Modified by Cedric Cannard (2023) to adjust colors, add markers, and
% percentage of data to plot in each sliding window.
%
% Copyright (c) 2016, Ellen Zakreski

function scrollplot(varargin)

% extract inputs
toPlot1 = varargin{1};      % data to plot
toPlot2 = varargin{2};      % additional data to plot on top (e.g., markers)
scrollOrient = varargin{3}; % Z for horizontal and Y for vertical
xLabel = varargin{4};       % label for x-axis
toDisplay = varargin{5};    % % of data to display in each window

% Plot handle (data to plot)
p = plot(toPlot1{:});

ax = p.Parent;

% Set initial axes limits to a portion of the total plotted X Data
% (unless the plot is empty or all NaN's)
XX = p.XData;
if ~isempty(XX)
    YY = p.YData;
    if ~all(isnan(XX))
        totxlim = [min(XX,[],'omitnan'),max(XX,[],'omitnan')];
        xlim = [totxlim(1),totxlim(1)+toDisplay*diff(totxlim)]; % arbitrarily show first 20%
    end

    % make all the Y data visible (unless Y data is all NaN's)
    if ~all(isnan(YY))
        ylim = [min(YY,[],'omitnan'),max(YY,[],'omitnan')];
    end
end
set(ax,'xlim',xlim,'ylim',ylim);

if ~isempty(xLabel)
    xlabel(xLabel)
end

% plot additional data (if any, e.g. markers)
if ~isempty(toPlot2)
    hold on; p = plot(toPlot2{:});
end

superscroll_obj = superscroll(ax,scrollOrient);

% build scrollbars here
autoscrollbar(superscroll_obj,p)

