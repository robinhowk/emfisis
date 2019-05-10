function [sweeprate, chorus_angle, p1best, p2best, p3best, p4best, rbest, knot1, knot2, knot3, segments, len_segments] = piecewise_regression(time, freq, mu)
    plot_fit = 0;
    p = polyfit(time, freq, 1);
    pf = polyval(p, time);

    % determine r^2 for line with no breaks
    % this is used to determine if a break point is good/needed
    r = 1 - (sum((freq - pf) .^ 2) / sum((freq - mean(freq)) .^ 2));

    % minimum length of segment is ~ 1/5 of the data points
    min_len = max(floor(length(time) / 5), 1);

    % find angle of single element fit to determine trend of element
    trend = atand(p(1) / mu);

    % values used to keep track of best fit
    rbest = r;
    p1best = p;
    p2best = 0;
    p3best = 0;
    p4best = 0;
    knot1 = 0;
    knot2 = 0;
    knot3 = 0;
    % default values for small elements
    segments = 1;
    f1best = pf;

    % r_elements = [];
    % p_elements = [];
%     if abs(trend) <= 5
%         chorus_angle = trend;
%         sweeprate = NaN;
%         return
%     end
    
    % trace is a straight line, best fit found with one segment
    if r == 1
        % return values and stop analyzing
        segments = 1;
        sweeprate = p1best(1);
        chorus_angle = atand(sweeprate / mu);
        len_segments = sqrt((((time(end) - time(1)) * mu) .^ 2) + ((f1best(end) - f1best(1)) .^ 2));
        if(plot_fit == 1)
%             figure;
%             plot(time, freq, 'b*', 'LineWidth', 5);
%             hold on;
            plot(time, f1best, 'r');
            
            rbest
            pause
            close
        end
        return
    end

    % for two segments work from left to right. Initially the left segment
    % is the minimum length. The breakpoint is moved to right and the
    % regression anaylsis is recomputed. The best scenario is saved.
    if (min_len * 2) < length(time)
        for index = min_len + 1:(length(time) - min_len + 1)
            % create each segment
            t1 = time(1:index);
            f1 = freq(1:index);
            t2 = time(index:end);
            f2 = freq(index:end);

            % find best fit for each segment
            p1 = polyfit(t1, f1, 1);
            p2 = polyfit(t2, f2, 1);
            pf1 = polyval(p1, t1);
            pf2 = polyval(p2, t2);

            % determine r squared for whole piecewise fit
            cd = 1 - ((sum(round((f1 - pf1) .^ 2, 6)) +  sum(round((f2 - pf2) .^ 2, 6))) / (sum(round((f1 - mean(freq)) .^ 2, 6)) + sum(round((f2 - mean(freq)) .^ 2, 6))));

            % if this maximizes r squared for the piecewise approximation, save the
            % break point and new max value
            if cd > rbest 
                rbest = cd;
                knot1 = index;
        %         r1best = r1;
        %         r2best = r2;
                p1best = p1;
                p2best = p2;
                f1best = pf1;
                f2best = pf2;
                segments = 2;

                % if cd is 1, a perfect fit is found. Return without further
                % analysis
                if (rbest == 1)
                    % pick the longest segment
                    len1 = sqrt((((time(knot1) - time(1)) * mu) .^ 2) + ((f1best(end) - f1(1)) .^ 2));
                    len2 = sqrt((((time(end) - time(knot1)) * mu) .^ 2) + ((f2best(end) - f2(1)) .^ 2));
                    len_segments = [len1 len2];

                    [~, longest_segment] = max(len_segments);

                    if longest_segment == 2
                        sweeprate = p2best(1);
                        chorus_angle = atand(sweeprate / mu);
                    else
                        sweeprate = p1best(1);
                        chorus_angle = atand(sweeprate / mu);
                    end 
                
                    if plot_fit == 1
    %                     figure;
    %                     plot(time, freq, 'b*', 'LineWidth', 5);
%                         hold on;
                        plot(time(1:knot1), f1best, 'r');
                        plot(time(knot1:end), f2best, 'r');

                        rbest
                        pause
                        close
                    end
                    return
                end      
            end
        end
    end
    
    % for three segments work from left to right. Initially the left segment
    % is the minimum length, the middle segment is the minimum length and the
    % right segment is the remaining points. The second break point is shifted
    % left until the right segment is the minimum length. The first break point
    % is then moved to the right by 1 and the process is repeated.
    if (min_len * 3) < length(time)
        % first break point
        for index1 = min_len + 1:(length(time) - (2 * (min_len - 1)))
        % determine first line segment
        t1 = time(1:index1);
        f1 = freq(1:index1);
        p1 = polyfit(t1, f1, 1);
        pf1 = polyval(p1, t1);

        % second break point
        for index2 = index1 + min_len:(length(time) - min_len + 1)
            % determine second line segment
            t2 = time(index1:index2);
            f2 = freq(index1:index2);
            p2 = polyfit(t2, f2, 1);
            pf2 = polyval(p2, t2);

            % determine third line segment
            t3 = time(index2:end);
            f3 = freq(index2:end);
            p3 = polyfit(t3, f3, 1);
            pf3 = polyval(p3, t3);

            cd = 1 - (sum(round((f1 - pf1) .^ 2, 6)) + sum(round((f2 - pf2) .^ 2, 6)) + sum(round((f3 - pf3) .^ 2, 6))) / (sum(round((f1 - mean(freq)) .^ 2, 6)) + sum(round((f2 - mean(freq)) .^ 2, 6)) + sum(round((f3 - mean(freq)) .^ 2, 6)));

            if cd > rbest
                rbest = cd;
                knot1 = index1;
                knot2 = index2;
                p1best = p1;
                p2best = p2;
                p3best = p3;
                f1best = pf1;
                f2best = pf2;
                f3best = pf3;
                segments = 3;

                % if cd = 1, a perfect fit is found. Return without further
                % processing
                if rbest == 1

                    % pick the longest segment
                    len1 = sqrt((((time(knot1) - time(1)) * mu) .^ 2) + ((f1best(end) - f1best(1)) .^ 2));
                    len2 = sqrt((((time(knot2) - time(knot1)) *mu) .^ 2) + ((f2best(end) - f2best(1)) .^ 2));
                    len3 = sqrt((((time(end) - time(knot2)) * mu) .^ 2) + ((f3best(end) - f3best(1)) .^ 2));
                    len_segments = [len1 len2 len3];

                    [~, longest_segment] = max(len_segments);

                    if longest_segment == 3
                        sweeprate = p3best(1);
                        chorus_angle = atand(sweeprate / mu);
                    elseif longest_segment == 2
                        sweeprate = p2best(1);
                        chorus_angle = atand(sweeprate / mu);
                    else
                        sweeprate = p1best(1);
                        chorus_angle = atand(sweeprate / mu);
                    end 
                    
                    if plot_fit == 1
%                         figure;
%                         plot(time, freq, 'b*', 'LineWidth', 5);
%                         hold on;
                        plot(time(1:knot1), f1best, 'r');
                        plot(time(knot1:knot2), f2best, 'r');
                        plot(time(knot2:end), f3best, 'r');
                        
                        rbest
                        pause
                        close
                    end
                    return
                end
            end
        end
        end
    end

    % for 4 segments work from left to right. Initially the left segments
    % is the minimum length, the middle segment is the minimum legnth, the
    % third segment is the minimum length and the right segment is the
    % remaining points.
%     min_len = max(floor(length(time) / 6),1);
%     if (min_len * 4) < length(time)
%         % first break point
%         for index1 = min_len:(length(time) - (3 * (min_len - 1)))
%         % determine first line segment
%         t1 = time(1:index1);
%         f1 = freq(1:index1);
%         p1 = polyfit(t1, f1, 1);
%         pf1 = polyval(p1, t1);
%         
%         % second break point
%         for index2 = index1 + min_len:(length(time) - (2 *  (min_len + 1)))
%             t2 = time(index1:index2);
%             f2 = freq(index1:index2);
%             p2 = polyfit(t2, f2, 1);
%             pf2 = polyval(p2, t2);
%             
%             for index3 = index2 + min_len:(length(time) - min_len + 1)
%                 t3 = time(index2:index3);
%                 f3 = freq(index2:index3);
%                 p3 = polyfit(t3, f3, 1);
%                 pf3 = polyval(p3, t3);
%                 
%                 t4 = time(index3:end);
%                 f4 = freq(index3:end);
%                 p4 = polyfit(t4, f4, 1);
%                 pf4 = polyval(p4, t4);
%                 
%                 cd = 1 - (sum([round((f1 - pf1) .^ 2, 6)  round((f2 - pf2) .^ 2, 6)  round((f3 - pf3) .^ 2, 6) round(f4 - pf4) .^ 2, 6]) / sum([round((f1 - mean(freq)) .^ 2, 6) round((f2 - mean(freq)) .^ 2, 6) round((f3 - mean(freq)) .^ 2, 6) round((f4 - mean(freq)) .^ 2, 6)]));
%                 
%                 if cd > rbest
%                     rbest = cd;
%                     knot1 = index1;
%                     knot2 = index2;
%                     knot3 = index3;
%                     p1best = p1;
%                     p2best = p2;
%                     p3best = p3;
%                     p4best = p4;
%                     f1best = pf1;
%                     f2best = pf2;
%                     f3best = pf3;
%                     f4best = pf4;
%                     segments = 4;
%                     
%                     % if cd = 1, a perfect fit is found. Return without further
%                     % processing
%                     if rbest == 1
%                         % pick the longest segment
%                         len1 = sqrt((((time(knot1) - time(1)) * mu) .^ 2) + ((f1best(end) - f2(1)) .^ 2));
%                         len2 = sqrt((((time(knot2) - time(knot1)) * mu) .^ 2) + ((f2best(end) - f2(1)) .^ 2));
%                         len3 = sqrt((((time(knot3) - time(knot2)) * mu) .^ 2) + ((f3best(end) - f3(1)) .^ 2));
%                         len4 = sqrt((((time(end) - time(knot3)) * mu) .^ 2) + ((f4best(end) - f4(1)) .^ 2));
%                         len_segments = [len1 len2 len3 len4];
% 
%                         [~, longest_segment] = max(len_segments);
% 
%                         if longest_segment == 4
%                             sweeprate = p4best(1);
%                             chorus_angle = atand(sweeprate / mu);
%                         elseif longest_segment == 3
%                             sweeprate = p3best(1);
%                             chorus_angle = atand(sweeprate / mu);
%                         elseif longest_segment == 2
%                             sweeprate = p2best(1);
%                             chorus_angle = atand(sweeprate / mu);
%                         else
%                             sweeprate = p1best(1);
%                             chorus_angle = atand(sweeprate / mu);
%                         end 
%                         
%                         if plot_fit == 1
% %                             figure;
% %                             plot(time, freq, 'b*', 'LineWidth', 5);
% %                             hold on;
%                             plot(time(1:knot1), f1best, 'r');
%                             plot(time(knot1:knot2), f2best, 'r');
%                             plot(time(knot2:knot3), f3best, 'r');
%                             plot(time(knot3:end), f4best, 'r');
%                             
%                             rbest
%                             pause
%                             close
%                         end
%                         return
%                     end
%                 end
%             end
%         end
%         end
%     end
    
%     if plot_fit == 1
%         figure;
%         plot(time, freq, 'b*', 'LineWidth', 5);
%     %     xlim([3.35 3.85]);
%         hold on;
%     end
    
%     len_segments = [];
    % pick the longest segment
    if segments == 4
        len1 = sqrt((((time(knot1) - time(1)) * mu) .^ 2) + ((f1best(end) - f1best(1)) .^ 2));
        len2 = sqrt((((time(knot2) - time(knot1)) * mu) .^ 2) + ((f2best(end) - f2best(1)) .^ 2));
        len3 = sqrt((((time(knot3) - time(knot2)) * mu) .^ 2) + ((f3best(end) - f3best(1)) .^ 2));
        len4 = sqrt((((time(end) - time(knot3)) * mu) .^ 2) + ((f4best(end) - f4best(1)) .^ 2));
        len_segments = [len1 len2 len3 len4];
        if plot_fit == 1
            plot(time(1:knot1), f1best, 'r');
            plot(time(knot1:knot2), f2best, 'r');
            plot(time(knot2:knot3), f3best, 'r');
            plot(time(knot3:end), f4best, 'r');
        end
    elseif segments == 3
        len1 = sqrt((((time(knot1) - time(1)) * mu).^ 2) + ((f1best(end) - f1best(1)) .^ 2));
        len2 = sqrt((((time(knot2) - time(knot1)) * mu) .^ 2) + ((f2best(end) - f2best(1)) .^ 2));
        len3 = sqrt((((time(end) - time(knot2)) * mu) .^ 2) + ((f3best(end) - f3best(1)) .^ 2));
        len_segments = [len1 len2 len3];
        if plot_fit == 1
            plot(time(1:knot1), f1best, 'r');
            plot(time(knot1:knot2), f2best, 'r');
            plot(time(knot2:end), f3best, 'r');
        end
    elseif segments == 2
        len1 = sqrt((((time(knot1) - time(1)) * mu) .^ 2) + ((f1best(end) - f1best(1)) .^ 2));
        len2 = sqrt((((time(end) - time(knot1)) * mu) .^ 2) + ((f2best(end) - f2best(1)) .^ 2));
        len_segments = [len1 len2];
        if plot_fit == 1
            plot(time(1:knot1), f1best, 'r');
            plot(time(knot1:end), f2best, 'r');
        end
    else
        len_segments = sqrt((((time(end) - time(1)) * mu) .^ 2) + ((f1best(end) - f1best(1)) .^ 2));
        if(plot_fit == 1)
            plot(time, f1best, 'r');
        end
    end
    
    if(plot_fit == 1)
        rbest
        pause
        close
    end
    
    [~, longest_segment] = max(len_segments);
    
    if longest_segment == 4
        sweeprate = p4best(1);
        chorus_angle = atand(sweeprate / mu);
    elseif longest_segment == 3
        sweeprate = p3best(1);
        chorus_angle = atand(sweeprate / mu);
    elseif longest_segment == 2
        sweeprate = p2best(1);
        chorus_angle = atand(sweeprate / mu);
    else
        sweeprate = p1best(1);
        chorus_angle = atand(sweeprate / mu);
    end
end