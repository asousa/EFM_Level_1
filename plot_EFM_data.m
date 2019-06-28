close all; clear all;
file_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Level 1/Without Site Corrections v2";
fig_dir = fullfile(file_dir, "figures");
sites = ["Cordoba","Manfredi","Pilar","Villa-Carlos-Paz", "Villa-del-Rosario"];

start_time = datetime(2018,10,28,0,0,0);
stop_time  = datetime(2018,12,20,0,0,0);

spans = datetime.empty(0,2);
spans = [spans; [datetime(2018,12,4,11,0,0 ), datetime(2018,12,5,10,0,0)] ];
spans = [spans; [datetime(2018,11,3,13,0,0 ), datetime(2018,11,4,11,0,0)] ];
spans = [spans; [datetime(2018,12,11,16,0,0), datetime(2018,12,11,22,0,0)] ];
spans = [spans; [datetime(2018,11,25,20,0,0), datetime(2018,11,27,20,0,0)] ];
spans = [spans; [datetime(2018,11,4,20,0,0 ), datetime(2018,11,7,10,0,0 )] ];
spans = [spans; [datetime(2018,11,29,14,0,0), datetime(2018,12,1,10,0,0 )] ];
spans = [spans; [datetime(2018,11,21,22,0,0), datetime(2018,11,22,23,0,0)] ];
spans = [spans; [datetime(2018,12,5,15,0,0 ), datetime(2018,12,6,4,0,0  )] ];
spans = [spans; [datetime(2018,12,13,16,0,0), datetime(2018,12,14,8,0,0 )] ];
spans = [spans; [datetime(2018,11,10,15,0,0), datetime(2018,11,13,6,0,0 )] ];
spans = [spans; [datetime(2018,11,2,23,0,0 ), datetime(2018,11,3,2,0,0  )] ];


days_to_do = start_time + days(0:(ceil(days(stop_time - start_time)) - 1));

for d=1:length(days_to_do)
    cur_day = days_to_do(d);
    next_day = cur_day + days(1);
    fprintf("Plotting %s\n",cur_day);
    dv1 = datevec(cur_day); dv2 = datevec(next_day);
    [fig,axs] = plot_time_range(cur_day, next_day, file_dir, sites);
    sgtitle({"EFM data without site correction",sprintf("%d/%d/%d - %d/%d/%d",dv1(3),dv1(2),dv1(1),dv2(3),dv2(2),dv2(1))});
    figtitle = fullfile(fig_dir, sprintf("%d-%d-%d.png",dv1(1),dv1(2), dv1(3)));
    saveas(fig, figtitle);
    close(fig);
end
    