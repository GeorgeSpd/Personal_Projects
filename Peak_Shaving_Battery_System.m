% DATA CHARACTERISTICS
Time_Steps_day = 24;

% IMPORTED DATA
Time = Data{(4 * Time_Steps_day + 1):8686,1}; % [d-m-y h:m:s]
Electricity_Consumption = Data{(4 * Time_Steps_day + 1):8686,2}; % [kWh]
Electricity_Price = Data{(4 * Time_Steps_day + 1):8686,3}; % [euros/kWh]
PV_Electricity_Production = Data{(4 * Time_Steps_day + 1):8686,4}; % [kWh]
Outdoor_Temperature = Data{(4 * Time_Steps_day + 1):8686,5}; % [C]

% BATTERY CHARACTERISTICS
Capacity_Battery = 5000; % Maximum Battery Capacity [kWh]
SOC = 5000; % Current state of charge [kWh]
Charge_Rate = 500; % [kW]
Discharge_Rate = 500; % [kW]

% GRID CHARACTERISTICS
Capacity_Grid = 8000; % Maximum Grid Power Capacity [kW]

% DEFINED LIMITS
Max_Grid_Capacity = 0.98 * Capacity_Grid; % Maximum Allowed Power Grid Capacity [kW]

Size = size(Electricity_Consumption);
Electricity_Consumption_Battery = [];
Revenue = [];
SOC_list = [];

for i = (1:Size)

% PEAK PREDICTION
Peak_Percentage_Identification_1st = (max(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}) - mean(Data{i + 1 * Time_Steps_day - 1:i + 1 * Time_Steps_day + 1,2})) / (max(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}));
Peak_Percentage_Identification_2nd = (max(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}) - mean(Data{i + 2 * Time_Steps_day - 1:i + 2 * Time_Steps_day + 1,2})) / (max(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}));
Peak_Percentage_Identification_3rd = (max(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}) - mean(Data{i + 3 * Time_Steps_day - 1:i + 3 * Time_Steps_day + 1,2})) / (max(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}));

% VALLEY PREDICTION
Off_Peak_Percentage_Identification_1st = (mean(Data{i + 1 * Time_Steps_day - 1:i + 1 * Time_Steps_day + 1,2}) - min(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2})) / (max(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}));
Off_Peak_Percentage_Identification_2nd = (mean(Data{i + 1 * Time_Steps_day - 1:i + 2 * Time_Steps_day + 1,2}) - min(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2})) / (max(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}));
Off_Peak_Percentage_Identification_3rd = (mean(Data{i + 1 * Time_Steps_day - 1:i + 3 * Time_Steps_day + 1,2}) - min(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2})) / (max(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}));

% MIN-MAX CONSUMPTION DIFFERENCE
Min_Max_Difference_1st = max(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 1 * Time_Steps_day - Time_Steps_day/2):(i + 1 * Time_Steps_day + Time_Steps_day/2),2});
Min_Max_Difference_2nd = max(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 2 * Time_Steps_day - Time_Steps_day/2):(i + 2 * Time_Steps_day + Time_Steps_day/2),2});
Min_Max_Difference_3rd = max(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2}) - min(Data{(i + 3 * Time_Steps_day - Time_Steps_day/2):(i + 3 * Time_Steps_day + Time_Steps_day/2),2});

    if Electricity_Consumption(i) >= Max_Grid_Capacity
       % During peak hours (>98% of Maximum Grid Power Capacity)
 
         if SOC > Electricity_Consumption(i) - Max_Grid_Capacity
            % If SOC > required trimming, battery can perform a full discharge step

             if Electricity_Consumption(i) - Max_Grid_Capacity < Discharge_Rate
                % If required trimming < Maximum Discharge Rate, DISCHARGE THE BATTERY: Trimming to exactly 98% of total capacity
    
                % Power Update
                Electricity_Updated = Max_Grid_Capacity - PV_Electricity_Production(i);
                Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                % Battery Capacity Update
                SOC = SOC - (Electricity_Consumption(i) - Max_Grid_Capacity);
                SOC_list = [SOC_list, SOC]; 
                % Revenue Update
                Revenue_updated = Electricity_Price(i) * (Electricity_Consumption(i) - Max_Grid_Capacity);
                Revenue = [Revenue, Revenue_updated];

           else % If Required trimming > Maximum Discharge Rate, DISCHARGE THE BATTERY: Trimming as much as possible

                % Power Update
                Electricity_Updated = Electricity_Consumption(i) - Discharge_Rate - PV_Electricity_Production(i); 
                Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                % Battery Capacity Update
                SOC = SOC - Discharge_Rate;
                SOC_list = [SOC_list, SOC];
                % Revenue Update
                Revenue_updated = Electricity_Price(i) * Discharge_Rate;
                Revenue = [Revenue, Revenue_updated];
             end

       else % If SOC < required trimming

             if Electricity_Consumption(i) - Max_Grid_Capacity < Discharge_Rate
                % If Required Trimming < Maximum Discharge rate, DISCHARGE THE BATTERY: Trimming as much as possible
    
                % Power Update
                Electricity_Updated = Electricity_Consumption(i) - SOC - PV_Electricity_Production(i);
                Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                % Revenue Update
                Revenue_updated = Electricity_Price(i) * SOC;
                Revenue = [Revenue, Revenue_updated];
                % Battery Capacity Update
                SOC = 0;
                SOC_list = [SOC_list, SOC];

           else % If Required Trimming > Maximum Discharge rate

                 if SOC < Discharge_Rate
                    % If SOC < Maximum Discharge Rate, DISCHARGE THE BATTERY: Fully discharge the battery

                    % Power Update
                    Electricity_Updated = Electricity_Consumption(i) - SOC - PV_Electricity_Production(i);
                    Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                    % Battery Capacity Update
                    SOC = 0;
                    SOC_list = [SOC_list, SOC];
                    % Revenue Update
                    Revenue_updated = Electricity_Price(i) * SOC;
                    Revenue = [Revenue, Revenue_updated];

               else % If SOC > Maximum Discharge Rate, DISCHARGE THE BATTERY: Trimming as much as possible

                    % Power Update
                    Electricity_Updated = Electricity_Consumption(i) - Discharge_Rate - PV_Electricity_Production(i); 
                    Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                    % Battery Capacity Update
                    SOC = SOC - Discharge_Rate;
                    SOC_list = [SOC_list, SOC];
                    % Revenue Update
                    Revenue_updated = Electricity_Price(i) * Discharge_Rate;
                    Revenue = [Revenue, Revenue_updated];
                 end
             end
         end
    
  elseif (Off_Peak_Percentage_Identification_1st < 0.1 && Min_Max_Difference_1st > 1500) || (Off_Peak_Percentage_Identification_2nd < 0.1 && Min_Max_Difference_2nd > 1500) || (Off_Peak_Percentage_Identification_3rd < 0.1 && Min_Max_Difference_3rd > 1500)
         % During off-peak hours (identified by consumption of previous 3 days & excluding weekdays)

       if SOC < Capacity_Battery - Charge_Rate

            if Electricity_Consumption(i) + Charge_Rate < Max_Grid_Capacity
               % CHARGE THE BATTERY with maximum charge rate
    
               % Power Update
               Electricity_Updated = Electricity_Consumption(i) + Charge_Rate - PV_Electricity_Production(i);
               Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
               % Battery Capacity Update
               SOC = SOC + Charge_Rate;
               SOC_list = [SOC_list, SOC];
               % Revenue Update
               Revenue_updated = - Electricity_Price(i) * Charge_Rate;
               Revenue = [Revenue, Revenue_updated];

          else % If Electricity_Consumption(i) + Charge_Rate > Max_Grid_Capacity, CHARGE THE BATTERY to exactly 98% of grid capacity

               % Power Update
               Electricity_Updated = Max_Grid_Capacity - PV_Electricity_Production(i);
               Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
               % Battery Capacity Update
               SOC = SOC + (Max_Grid_Capacity - Electricity_Consumption(i));
               SOC_list = [SOC_list, SOC];
               % Revenue Update
               Revenue_updated = - Electricity_Price(i) * (Max_Grid_Capacity - Electricity_Consumption(i));
               Revenue = [Revenue, Revenue_updated];
            end

     else % If SOC > Capacity_Battery - Charge_Rate
           
            if Electricity_Consumption(i) + Charge_Rate < Max_Grid_Capacity
               % CHARGE THE BATTERY to maximum capacity
   
               % Power Update
               Electricity_Updated = Electricity_Consumption(i) + (Capacity_Battery - SOC) - PV_Electricity_Production(i);
               Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
               % Battery Capacity Update
               SOC = Capacity_Battery;
               SOC_list = [SOC_list, SOC];
               % Revenue Update
               Revenue_updated = - Electricity_Price(i) * (Capacity_Battery - SOC);
               Revenue = [Revenue, Revenue_updated];

            else % if Electricity_Consumption(i) + Charge_Rate > Max_Grid_Capacity

                if Capacity_Battery - SOC < Max_Grid_Capacity - Electricity_Consumption(i)
                   % CHARGE THE BATTERY to maximum capacity

                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) + (Capacity_Battery - SOC);
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC = Capacity_Battery;
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = - Electricity_Price(i) * (Capacity_Battery - SOC);
                   Revenue = [Revenue, Revenue_updated];

              else % If Capacity_Battery - SOC > Max_Grid_Capacity - Electricity_Consumption(i), CHARGE THE BATTERY till 98% of grid capacity

                   % Power Update
                   Electricity_Updated = Max_Grid_Capacity;
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC = SOC + (Max_Grid_Capacity - Electricity_Consumption(i));
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = - Electricity_Price(i) * (Max_Grid_Capacity - Electricity_Consumption(i));
                   Revenue = [Revenue, Revenue_updated];
                end
            end
        end

  else % Between peak and off-peak hours 

        if (Peak_Percentage_Identification_1st < 0.15 && Min_Max_Difference_1st > 1500) || (Peak_Percentage_Identification_2nd < 0.15 && Min_Max_Difference_2nd > 1500) || (Peak_Percentage_Identification_3rd < 0.15 && Min_Max_Difference_3rd > 1500)
           % Determine the peak hour (identified by consumption of previous 3 days & excluding weekdays)

           if mean(Data{(3 * Time_Steps_day + i):(4 * Time_Steps_day + i),5}) > 5
              % If mean temperature of the previous day is > 5

               if SOC <= Discharge_Rate
                   % DISCHARGE THE BATTERY: Fully discharge the battery
    
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - SOC - PV_Electricity_Production(i);
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Revenue Update
                   Revenue_updated = Electricity_Price(i) * SOC;
                   Revenue = [Revenue, Revenue_updated];
                   % Battery Capacity Update
                   SOC = 0;
                   SOC_list = [SOC_list, SOC];
    
            elseif SOC > Discharge_Rate  
                   % DISCHARGE THE BATTERY with maximum discharge rate
                   
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - Discharge_Rate - PV_Electricity_Production(i); 
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC = SOC - Discharge_Rate;
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = Electricity_Price(i) * Discharge_Rate;
                   Revenue = [Revenue, Revenue_updated];
    
              else % If SOC < 0.4 of maximum battery capacity do nothing
    
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - PV_Electricity_Production(i);
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = 0;
                   Revenue = [Revenue, Revenue_updated];
               end

           else % If mean temperature of the previous day is < 5

                if SOC < 0.4 * Capacity_Battery + Discharge_Rate && SOC > 0.4 * Capacity_Battery
                   % DISCHARGE THE BATTERY: Exactly to 0.4 of Total Capacity
    
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - (SOC - 0.4 * Capacity_Battery) - PV_Electricity_Production(i);
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Revenue Update
                   Revenue_updated = Electricity_Price(i) * (SOC - 0.4 * Capacity_Battery);
                   Revenue = [Revenue, Revenue_updated];
                   % Battery Capacity Update
                   SOC = 0.4 * Capacity_Battery;
                   SOC_list = [SOC_list, SOC];
    
            elseif SOC > 0.4 * Capacity_Battery + Discharge_Rate  
                   % DISCHARGE THE BATTERY with maximum discharge rate
                   
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - Discharge_Rate - PV_Electricity_Production(i); 
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC = SOC - Discharge_Rate;
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = Electricity_Price(i) * Discharge_Rate;
                   Revenue = [Revenue, Revenue_updated];
    
              else % If SOC < 0.4 of maximum battery capacity do nothing
    
                   % Power Update
                   Electricity_Updated = Electricity_Consumption(i) - PV_Electricity_Production(i);
                   Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
                   % Battery Capacity Update
                   SOC_list = [SOC_list, SOC];
                   % Revenue Update
                   Revenue_updated = 0;
                   Revenue = [Revenue, Revenue_updated];
                end
           end

        else % During average consumption do nothing

           % Power Update
           Electricity_Updated = Electricity_Consumption(i) - PV_Electricity_Production(i);
           Electricity_Consumption_Battery = [Electricity_Consumption_Battery, Electricity_Updated];
           % Battery Capacity Update
           SOC_list = [SOC_list, SOC];
           % Revenue Update
           Revenue_updated = 0;
           Revenue = [Revenue, Revenue_updated];
        end
    end
end

% DATA TRANSFORMATION
Electricity_Consumption_Battery_Graph = reshape(Electricity_Consumption_Battery, [], 1);
Revenue_Graph = reshape(Revenue, [], 1);
SOC_list_Graph = reshape(SOC_list, [], 1);


figure
% Electricity Consumption with and without Battery
bar(Time, Electricity_Consumption);
hold on
bar(Time, Electricity_Consumption_Battery_Graph);
ylabel('Electricity [kWh]')
xlabel('Time [date, time]')
grid on
legend('Electricity Consumption [kWh]', 'Updated Electricity Consumption [kWh]')


figure
% Electricity Consumption with and without Battery, Battery Charge & Revenue generated
bar(Time, Electricity_Consumption, 'FaceAlpha', 0.65);
hold on;
bar(Time, Electricity_Consumption_Battery_Graph, 'FaceAlpha', 0.65);

yyaxis right
ylabel('Revenue [euros]');
plot(Time, Revenue, 'LineWidth', 1);
ylim([-2000 10000]);

yyaxis left
ylabel('Electricity [kWh]');
plot(Time, SOC_list, 'LineWidth', 1, 'Color', [0.1 0.1 0.1]);

legend('Electricity Consumption [kWh]', 'Updated Electricity Consumption [kWh]', 'Current Battery Capacity [kWh]', 'Revenue [euros]');
xlabel('Time [date, time]');
grid on;


figure
% Outside Temperature - Electricity Consumption
yyaxis left
bar(Time, Electricity_Consumption);
ylabel('Electricity [kWh]');
hold on

yyaxis right
plot(Time, Outdoor_Temperature, 'LineWidth', 1)
ylabel('Temperature [C]')
ylim([-20 100]);

legend('Electricity Consumption', 'Outdoor Temperature')
xlabel('Time [date, time]')
grid on

% Yearly Revenue
Revenue_tot = sum(Revenue); % [euros]
