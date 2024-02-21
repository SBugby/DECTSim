classdef sensor_tests < matlab.unittest.TestCase

    methods(Test)
        function test_init(tc)
            is = ideal_sensor([0, 10], 100);
            tc.verifyEqual(is.num_bins, 100);
            tc.verifyEqual(is.bin_width, 0.1);
            tc.verifyEqual(is.energy_range, [0, 10]);
            tc.verifyEqual(is.energy_bins, 0:0.1:10);

            is = ideal_sensor([4, 32], 83);
            tc.verifyEqual(is.num_bins, 83);
            tc.verifyEqual(is.bin_width, 28/83);
            tc.verifyEqual(is.energy_range, [4, 32]);
            tc.verifyEqual(is.energy_bins, 4:28/83:32);
            
            tc.verifyError(@() ideal_sensor([0, 10], 0), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() ideal_sensor([0, 10], -1), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() ideal_sensor([10, 0], 100), 'sensor:IncorrectEnergyRange');
            tc.verifyError(@() ideal_sensor([10, 10], 100), 'sensor:IncorrectEnergyRange');
            tc.verifyError(@() ideal_sensor([-10, 10], 100), 'MATLAB:validators:mustBeNonnegative');
            tc.verifyError(@() ideal_sensor([0, 10], 100.5), 'MATLAB:validators:mustBeInteger');
        end

        function test_ideal_sensor(tc)
            is = ideal_sensor([0, 10], 100);

            % test get_energy_bin
            tc.verifyEqual(is.get_energy_bin(4.2), 43);
            tc.verifyEqual(is.get_energy_bin(4.29), 43);
            tc.verifyEqual(is.get_energy_bin(0), 1);
            tc.verifyEqual(is.get_energy_bin(9.99), 100);

            % test detector_response
            tc.verifyEqual(is.detector_response(43, 2), 2 * 4.25);
            tc.verifyEqual(is.detector_response(1, 2), 2 * 0.05);
            tc.verifyEqual(is.detector_response(100, 0.3), 0.3 * 9.95);
            tc.verifyEqual(is.detector_response([10, 20, 30, 40], [1, 2, 3, 4]), [0.95, 3.9, 8.85, 15.8], 'RelTol', 1e-15) 

            % test get_image
            image = rand(100, 100);
            image(50, 50) = 2;
            tc.verifyEqual(is.get_image(image), -log(image./2))

            % test get_signal
            image = rand(100, 10, 10, 10);
            tc.verifyEqual(size(is.get_signal(image)), [10, 10, 10]);
            signal = zeros(10, 10, 10);
            e_range = 0:0.1:9.9; 
            for i = 1:100
                signal = signal + ...
                    reshape(image(i,:,:,:), [10 10 10]) .* (e_range(i) + 0.05);
            end
            tc.verifyEqual(is.get_signal(image), signal, 'RelTol', 1e-15)

            s1 = single_energy(50);
            tc.verifyEqual(s1.energy, 50);
            is = ideal_sensor([0, 60], 6);
            expE = [NaN; NaN; NaN; NaN; NaN; 50];
            expI = [NaN; NaN; NaN; NaN; NaN; 1];
            [e, i] = is.sample_source(s1);
            tc.verifyEqual(e, expE);
            tc.verifyEqual(i, expI);

            s2 = single_energy(21);
            tc.verifyEqual(s2.energy, 21);
            is = ideal_sensor([0, 56], 8);
            expE = [NaN; NaN; NaN; 21; NaN; NaN; NaN; NaN];
            expI = [NaN; NaN; NaN; 1; NaN; NaN; NaN; NaN];
            [e, i] = is.sample_source(s2);
            tc.verifyEqual(e, expE);
            tc.verifyEqual(i, expI);
        end


    end
end