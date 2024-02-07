function att_fun = get_photon_attenuation(z, fracs, density)
%PhotonAttenuationQ NIST attenuation cooeficiant tables
% for photon interaction with elements.
%
% att_fun = photon_attenuation(z, fracs)
% Function providing the attenuation of various elements,
% based on NIST report 5632, by % J. Hubbell and S.M. Seltzer.
% This is a quick version of the function with
% narrow range of inputs and outputs.
%
% Input :
%   z - atomic number Z in [1, 100] range, or array of Z numbers
%   fracs - mass fractions of each element in the material, should sum to 1
%   density - density of the material in g/cm^3
%
% Output :
%   att_fun - A function handle for the for the attenuation coefficients
%   in cm^-1 that takes in energy in KeV and returns the attenuation
%
% History:
%  Written by Jarek Tuszynski (SAIC), 2006
%  Updated by Jarek Tuszynski (Leidos), 2014, jaroslaw.w.tuszynski@leidos.com
%  Inspired by John Schweppe Mathematica code available at
%    http://library.wolfram.com/infocenter/MathSource/4267/
%  Cut Down by Joshua Gray 2024
%
%
% References:
%   Tables are based on "X-Ray Attenuation and Absorption for Materials of
%   Dosimetric Interest" (XAAMDI) database (NIST 5632 report):
%   J. Hubbell and S.M. Seltzer, "Tables of X-Ray Mass Attenuation
%   Coefficients and Mass Energy-Absorption Coefficients 1 keV to 20 MeV for
%   Elements Z = 1 to 92 and 48 Additional Substances of Dosimetric Interest, "
%   National Institute of Standards and Technology report NISTIR 5632 (1995).
%   http://physics.nist.gov/PhysRefData/XrayMassCoef/cover.html
%
%   MAC values for elements 93 to 100 (Neptunium to Fermium) came from
%   XCOM: Photon Cross Sections Database (NBSIR 87-3597):
%   Those tables give photon's "total attenuation coefficients" for
%   elements with atomic number (Z) smaller than 100.
%   Photon energy range is from 0.001 MeV to 100 GeV.
%   http://physics.nist.gov/PhysRefData/Xcom/Text/XCOM.html
%
%   This code was originally written in the PhotonAttenuation MATLAB package
%   available at: https://uk.mathworks.com/matlabcentral/fileexchange/12092-photonattenuation
%   It has been modified to be less versatile and more efficient, returning
%   functions that takes in energy and the attenuation
%
% Details:
%   This function is intended as a simpler and faster version of
%   PhotonAttenuationQ function and contain mostly the NIST tables and a
%   little code to look them up and interpolate results. Very few input
%   options are allowed.
%
%   The Attenuation tables are stored in two formats: standard grid values
%   defined for all the elements and values at absorbtion edges are stored
%   separately. That way they take less space and absorbtion edge data is
%   easier to extract. The values in the table are for room temperature
%   and pressure.
%
%   Interpolation is done using MATLAB's interp1 function to log-log data of
%   coefficients as function of energy. Linear interpolation is used near
%   absorbtion edges and cubic otherwise.
%

%--------------------------------------------------------------------------
% Hard-wire the table of x-ray mass attenuation coefficients (MAC) Units:
% energy is in MeV, and MAC is in cm^2/g.
% The table contains values using uniform energy sampling. NIST tables
% contain both values for uniform energy sampling and for the non-uniform
% absorption edges.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%% Hard-wire the table of x-ray mass attenuation coefficients in cm^2/g
%--------------------------------------------------------------------------

energy = [... % in keV
    1.000E-3, 1.500E-3, 2.000E-3, 3.000E-3, 4.000E-3, 5.000E-3, 6.000E-3, 8.000E-3, 1.000E-2, 1.500E-2, 2.000E-2, 3.000E-2, 4.000E-2, 5.000E-2, 6.000E-2, 8.000E-2, 1.000E-1, 1.500E-1, 2.000E-1, 3.000E-1].*1000;
mac = [...                                                                                                                                                                                                            
    7.217   , 2.148   , 1.059   , 5.612E-1, 4.546E-1, 4.193E-1, 4.042E-1, 3.914E-1, 3.854E-1, 3.764E-1, 3.695E-1, 3.570E-1, 3.458E-1, 3.355E-1, 3.260E-1, 3.091E-1, 2.944E-1, 2.651E-1, 2.429E-1, 2.112E-1;...
    6.084E+1, 1.676E+1, 6.863   , 2.007   , 9.329E-1, 5.766E-1, 4.195E-1, 2.933E-1, 2.476E-1, 2.092E-1, 1.960E-1, 1.838E-1, 1.763E-1, 1.703E-1, 1.651E-1, 1.562E-1, 1.486E-1, 1.336E-1, 1.224E-1, 1.064E-1;...
    2.339E+2, 6.668E+1, 2.707E+1, 7.549   , 3.114   , 1.619   , 9.875E-1, 5.054E-1, 3.395E-1, 2.176E-1, 1.856E-1, 1.644E-1, 1.551E-1, 1.488E-1, 1.438E-1, 1.356E-1, 1.289E-1, 1.158E-1, 1.060E-1, 9.210E-2;...
    6.041E+2, 1.797E+2, 7.469E+1, 2.127E+1, 8.685   , 4.369   , 2.527   , 1.124   , 6.466E-1, 3.070E-1, 2.251E-1, 1.792E-1, 1.640E-1, 1.554E-1, 1.493E-1, 1.401E-1, 1.328E-1, 1.190E-1, 1.089E-1, 9.463E-2;...
    1.229E+3, 3.766E+2, 1.597E+2, 4.667E+1, 1.927E+1, 9.683   , 5.538   , 2.346   , 1.255   , 4.827E-1, 3.014E-1, 2.063E-1, 1.793E-1, 1.665E-1, 1.583E-1, 1.472E-1, 1.391E-1, 1.243E-1, 1.136E-1, 9.862E-2;...
    2.211E+3, 7.002E+2, 3.026E+2, 9.033E+1, 3.778E+1, 1.912E+1, 1.095E+1, 4.576   , 2.373   , 8.071E-1, 4.420E-1, 2.562E-1, 2.076E-1, 1.871E-1, 1.753E-1, 1.610E-1, 1.514E-1, 1.347E-1, 1.229E-1, 1.066E-1;...
    3.311E+3, 1.083E+3, 4.769E+2, 1.456E+2, 6.166E+1, 3.144E+1, 1.809E+1, 7.562   , 3.879   , 1.236   , 6.178E-1, 3.066E-1, 2.288E-1, 1.980E-1, 1.817E-1, 1.639E-1, 1.529E-1, 1.353E-1, 1.233E-1, 1.068E-1;...
    4.590E+3, 1.549E+3, 6.949E+2, 2.171E+2, 9.315E+1, 4.790E+1, 2.770E+1, 1.163E+1, 5.952   , 1.836   , 8.651E-1, 3.779E-1, 2.585E-1, 2.132E-1, 1.907E-1, 1.678E-1, 1.551E-1, 1.361E-1, 1.237E-1, 1.070E-1;...
    5.649E+3, 1.979E+3, 9.047E+2, 2.888E+2, 1.256E+2, 6.514E+1, 3.789E+1, 1.602E+1, 8.205   , 2.492   , 1.133   , 4.487E-1, 2.828E-1, 2.214E-1, 1.920E-1, 1.639E-1, 1.496E-1, 1.298E-1, 1.176E-1, 1.015E-1;...
    7.409E+3, 2.666E+3, 1.243E+3, 4.051E+2, 1.785E+2, 9.339E+1, 5.467E+1, 2.328E+1, 1.197E+1, 3.613   , 1.606   , 5.923E-1, 3.473E-1, 2.579E-1, 2.161E-1, 1.781E-1, 1.600E-1, 1.370E-1, 1.236E-1, 1.064E-1;...
    6.542E+2, 3.194E+3, 1.521E+3, 5.070E+2, 2.261E+2, 1.194E+2, 7.030E+1, 3.018E+1, 1.557E+1, 4.694   , 2.057   , 7.197E-1, 3.969E-1, 2.804E-1, 2.268E-1, 1.796E-1, 1.585E-1, 1.335E-1, 1.199E-1, 1.029E-1;...
    9.225E+2, 4.004E+3, 1.932E+3, 6.585E+2, 2.974E+2, 1.583E+2, 9.381E+1, 4.061E+1, 2.105E+1, 6.358   , 2.763   , 9.306E-1, 4.881E-1, 3.292E-1, 2.570E-1, 1.951E-1, 1.686E-1, 1.394E-1, 1.245E-1, 1.065E-1;...
    1.185E+3, 4.022E+2, 2.263E+3, 7.880E+2, 3.605E+2, 1.934E+2, 1.153E+2, 5.033E+1, 2.623E+1, 7.955   , 3.441   , 1.128   , 5.685E-1, 3.681E-1, 2.778E-1, 2.018E-1, 1.704E-1, 1.378E-1, 1.223E-1, 1.042E-1;...
    1.570E+3, 5.355E+2, 2.777E+3, 9.784E+2, 4.529E+2, 2.450E+2, 1.470E+2, 6.468E+1, 3.389E+1, 1.034E+1, 4.464   , 1.436   , 7.012E-1, 4.385E-1, 3.207E-1, 2.228E-1, 1.835E-1, 1.448E-1, 1.275E-1, 1.082E-1;...
    1.913E+3, 6.547E+2, 3.018E+2, 1.118E+3, 5.242E+2, 2.860E+2, 1.726E+2, 7.660E+1, 4.035E+1, 1.239E+1, 5.352   , 1.700   , 8.096E-1, 4.916E-1, 3.494E-1, 2.324E-1, 1.865E-1, 1.432E-1, 1.250E-1, 1.055E-1;...
    2.429E+3, 8.342E+2, 3.853E+2, 1.339E+3, 6.338E+2, 3.487E+2, 2.116E+2, 9.465E+1, 5.012E+1, 1.550E+1, 6.708   , 2.113   , 9.872E-1, 5.849E-1, 4.053E-1, 2.585E-1, 2.020E-1, 1.506E-1, 1.302E-1, 1.091E-1;...
    2.832E+3, 9.771E+2, 4.520E+2, 1.473E+3, 7.037E+2, 3.901E+2, 2.384E+2, 1.075E+2, 5.725E+1, 1.784E+1, 7.739   , 2.425   , 1.117   , 6.483E-1, 4.395E-1, 2.696E-1, 2.050E-1, 1.480E-1, 1.266E-1, 1.054E-1;...
    3.184E+3, 1.105E+3, 5.120E+2, 1.703E+2, 7.572E+2, 4.225E+2, 2.593E+2, 1.180E+2, 6.316E+1, 1.983E+1, 8.629   , 2.697   , 1.228   , 7.012E-1, 4.664E-1, 2.760E-1, 2.043E-1, 1.427E-1, 1.205E-1, 9.953E-2;...
    4.058E+3, 1.418E+3, 6.592E+2, 2.198E+2, 9.256E+2, 5.189E+2, 3.205E+2, 1.469E+2, 7.907E+1, 2.503E+1, 1.093E+1, 3.413   , 1.541   , 8.679E-1, 5.678E-1, 3.251E-1, 2.345E-1, 1.582E-1, 1.319E-1, 1.080E-1;...
    4.867E+3, 1.714E+3, 7.999E+2, 2.676E+2, 1.218E+2, 6.026E+2, 3.731E+2, 1.726E+2, 9.341E+1, 2.979E+1, 1.306E+1, 4.080   , 1.830   , 1.019   , 6.578E-1, 3.656E-1, 2.571E-1, 1.674E-1, 1.376E-1, 1.116E-1;...
    5.238E+3, 1.858E+3, 8.706E+2, 2.922E+2, 1.332E+2, 6.305E+2, 3.933E+2, 1.828E+2, 9.952E+1, 3.202E+1, 1.409E+1, 4.409   , 1.969   , 1.087   , 6.932E-1, 3.753E-1, 2.577E-1, 1.619E-1, 1.310E-1, 1.052E-1;...
    5.869E+3, 2.096E+3, 9.860E+2, 3.323E+2, 1.517E+2, 6.838E+2, 4.323E+2, 2.023E+2, 1.107E+2, 3.587E+1, 1.585E+1, 4.972   , 2.214   , 1.213   , 7.661E-1, 4.052E-1, 2.721E-1, 1.649E-1, 1.314E-1, 1.043E-1;...
    6.495E+3, 2.342E+3, 1.106E+3, 3.743E+2, 1.712E+2, 9.291E+1, 4.687E+2, 2.217E+2, 1.218E+2, 3.983E+1, 1.768E+1, 5.564   , 2.472   , 1.347   , 8.438E-1, 4.371E-1, 2.877E-1, 1.682E-1, 1.318E-1, 1.034E-1;...
    7.405E+3, 2.694E+3, 1.277E+3, 4.339E+2, 1.988E+2, 1.080E+2, 5.160E+2, 2.513E+2, 1.386E+2, 4.571E+1, 2.038E+1, 6.434   , 2.856   , 1.550   , 9.639E-1, 4.905E-1, 3.166E-1, 1.788E-1, 1.378E-1, 1.067E-1;...
    8.093E+3, 2.984E+3, 1.421E+3, 4.851E+2, 2.229E+2, 1.212E+2, 7.350E+1, 2.734E+2, 1.514E+2, 5.027E+1, 2.253E+1, 7.141   , 3.169   , 1.714   , 1.060   , 5.306E-1, 3.367E-1, 1.838E-1, 1.391E-1, 1.062E-1;...
    9.085E+3, 3.399E+3, 1.626E+3, 5.576E+2, 2.567E+2, 1.398E+2, 8.484E+1, 3.056E+2, 1.706E+2, 5.708E+1, 2.568E+1, 8.176   , 3.629   , 1.958   , 1.205   , 5.952E-1, 3.717E-1, 1.964E-1, 1.460E-1, 1.099E-1;...
    9.796E+3, 3.697E+3, 1.779E+3, 6.129E+2, 2.830E+2, 1.543E+2, 9.370E+1, 3.248E+2, 1.841E+2, 6.201E+1, 2.803E+1, 8.962   , 3.981   , 2.144   , 1.314   , 6.414E-1, 3.949E-1, 2.023E-1, 1.476E-1, 1.094E-1;...
    9.855E+3, 4.234E+3, 2.049E+3, 7.094E+2, 3.282E+2, 1.793E+2, 1.090E+2, 4.952E+1, 2.090E+2, 7.081E+1, 3.220E+1, 1.034E+1, 4.600   , 2.474   , 1.512   , 7.306E-1, 4.440E-1, 2.208E-1, 1.582E-1, 1.154E-1;...
    1.057E+4, 4.418E+3, 2.154E+3, 7.488E+2, 3.473E+2, 1.899E+2, 1.156E+2, 5.255E+1, 2.159E+2, 7.405E+1, 3.379E+1, 1.092E+1, 4.862   , 2.613   , 1.593   , 7.630E-1, 4.584E-1, 2.217E-1, 1.559E-1, 1.119E-1;...
    1.553E+3, 4.825E+3, 2.375E+3, 8.311E+2, 3.865E+2, 2.118E+2, 1.290E+2, 5.875E+1, 2.331E+2, 8.117E+1, 3.719E+1, 1.207E+1, 5.384   , 2.892   , 1.760   , 8.364E-1, 4.973E-1, 2.341E-1, 1.617E-1, 1.141E-1;...
    1.697E+3, 5.087E+3, 2.515E+3, 8.857E+2, 4.130E+2, 2.266E+2, 1.382E+2, 6.302E+1, 3.421E+1, 8.537E+1, 3.928E+1, 1.281E+1, 5.726   , 3.076   , 1.868   , 8.823E-1, 5.197E-1, 2.387E-1, 1.619E-1, 1.123E-1;...
    1.893E+3, 5.475E+3, 2.711E+3, 9.613E+2, 4.497E+2, 2.472E+2, 1.509E+2, 6.890E+1, 3.742E+1, 9.152E+1, 4.222E+1, 1.385E+1, 6.207   , 3.335   , 2.023   , 9.501E-1, 5.550E-1, 2.491E-1, 1.661E-1, 1.131E-1;...
    2.121E+3, 5.227E+3, 2.931E+3, 1.049E+3, 4.920E+2, 2.709E+2, 1.656E+2, 7.573E+1, 4.115E+1, 9.856E+1, 4.564E+1, 1.506E+1, 6.760   , 3.635   , 2.203   , 1.030   , 5.971E-1, 2.622E-1, 1.719E-1, 1.150E-1;...
    2.317E+3, 5.336E+3, 3.098E+3, 1.116E+3, 5.252E+2, 2.896E+2, 1.773E+2, 8.116E+1, 4.414E+1, 1.033E+2, 4.818E+1, 1.596E+1, 7.184   , 3.864   , 2.341   , 1.090   , 6.278E-1, 2.703E-1, 1.742E-1, 1.144E-1;...
    2.624E+3, 1.002E+3, 3.407E+3, 1.231E+3, 5.815E+2, 3.213E+2, 1.968E+2, 9.026E+1, 4.912E+1, 1.119E+2, 5.266E+1, 1.753E+1, 7.900   , 4.264   , 2.582   , 1.198   , 6.861E-1, 2.899E-1, 1.838E-1, 1.186E-1;...
    2.854E+3, 1.093E+3, 3.599E+3, 1.305E+3, 6.186E+2, 3.425E+2, 2.101E+2, 9.651E+1, 5.257E+1, 1.168E+2, 5.548E+1, 1.854E+1, 8.389   , 4.523   , 2.739   , 1.267   , 7.221E-1, 2.998E-1, 1.872E-1, 1.186E-1;...
    3.174E+3, 1.219E+3, 3.410E+3, 1.418E+3, 6.748E+2, 3.744E+2, 2.300E+2, 1.058E+2, 5.766E+1, 1.909E+1, 5.980E+1, 2.009E+1, 9.112   , 4.918   , 2.979   , 1.375   , 7.799E-1, 3.187E-1, 1.960E-1, 1.219E-1;...
    3.494E+3, 1.347E+3, 2.589E+3, 1.525E+3, 7.297E+2, 4.058E+2, 2.496E+2, 1.150E+2, 6.274E+1, 2.079E+1, 6.386E+1, 2.157E+1, 9.818   , 5.306   , 3.214   , 1.481   , 8.365E-1, 3.369E-1, 2.042E-1, 1.247E-1;...
    3.864E+3, 1.493E+3, 7.422E+2, 1.654E+3, 7.936E+2, 4.424E+2, 2.725E+2, 1.258E+2, 6.871E+1, 2.279E+1, 6.855E+1, 2.330E+1, 1.065E+1, 5.764   , 3.493   , 1.607   , 9.047E-1, 3.595E-1, 2.149E-1, 1.289E-1;...
    4.210E+3, 1.631E+3, 8.115E+2, 1.772E+3, 8.507E+2, 4.755E+2, 2.935E+2, 1.356E+2, 7.417E+1, 2.463E+1, 7.237E+1, 2.485E+1, 1.139E+1, 6.173   , 3.744   , 1.721   , 9.658E-1, 3.790E-1, 2.237E-1, 1.318E-1;...
    4.600E+3, 1.786E+3, 8.893E+2, 1.906E+3, 9.164E+2, 5.134E+2, 3.172E+2, 1.469E+2, 8.038E+1, 2.672E+1, 7.712E+1, 2.666E+1, 1.223E+1, 6.644   , 4.032   , 1.852   , 1.037   , 4.023E-1, 2.344E-1, 1.357E-1;...
    4.942E+3, 1.925E+3, 9.593E+2, 2.011E+3, 9.703E+2, 5.450E+2, 3.373E+2, 1.565E+2, 8.576E+1, 2.854E+1, 8.054E+1, 2.810E+1, 1.294E+1, 7.037   , 4.274   , 1.962   , 1.096   , 4.208E-1, 2.423E-1, 1.379E-1;...
    5.356E+3, 2.092E+3, 1.044E+3, 1.862E+3, 1.036E+3, 5.836E+2, 3.619E+2, 1.683E+2, 9.231E+1, 3.076E+1, 1.410E+1, 2.993E+1, 1.381E+1, 7.521   , 4.571   , 2.099   , 1.169   , 4.449E-1, 2.534E-1, 1.418E-1;...
    5.718E+3, 2.240E+3, 1.120E+3, 1.963E+3, 1.095E+3, 6.165E+2, 3.832E+2, 1.785E+2, 9.800E+1, 3.270E+1, 1.499E+1, 3.139E+1, 1.452E+1, 7.926   , 4.822   , 2.215   , 1.232   , 4.647E-1, 2.618E-1, 1.440E-1;...
    6.169E+3, 2.426E+3, 1.214E+3, 4.441E+2, 1.170E+3, 6.589E+2, 4.101E+2, 1.915E+2, 1.053E+2, 3.518E+1, 1.613E+1, 3.330E+1, 1.544E+1, 8.448   , 5.147   , 2.365   , 1.314   , 4.916E-1, 2.742E-1, 1.485E-1;...
    6.538E+3, 2.579E+3, 1.292E+3, 4.730E+2, 1.227E+3, 6.912E+2, 4.308E+2, 2.017E+2, 1.110E+2, 3.715E+1, 1.704E+1, 3.465E+1, 1.614E+1, 8.850   , 5.399   , 2.481   , 1.377   , 5.115E-1, 2.827E-1, 1.506E-1;...
    7.039E+3, 2.790E+3, 1.401E+3, 5.136E+2, 1.305E+3, 7.385E+2, 4.610E+2, 2.164E+2, 1.193E+2, 3.998E+1, 1.836E+1, 3.668E+1, 1.720E+1, 9.444   , 5.766   , 2.651   , 1.470   , 5.426E-1, 2.972E-1, 1.560E-1;...
    7.350E+3, 2.931E+3, 1.473E+3, 5.414E+2, 1.170E+3, 7.685E+2, 4.793E+2, 2.254E+2, 1.244E+2, 4.178E+1, 1.920E+1, 3.765E+1, 1.778E+1, 9.779   , 5.975   , 2.751   , 1.524   , 5.593E-1, 3.038E-1, 1.571E-1;...
    7.809E+3, 3.131E+3, 1.578E+3, 5.808E+2, 1.231E+3, 8.134E+2, 5.072E+2, 2.391E+2, 1.321E+2, 4.445E+1, 2.044E+1, 3.949E+1, 1.873E+1, 1.030E+1, 6.306   , 2.907   , 1.609   , 5.876E-1, 3.167E-1, 1.614E-1;...
    8.157E+3, 3.296E+3, 1.665E+3, 6.143E+2, 9.393E+2, 8.471E+2, 5.294E+2, 2.500E+2, 1.384E+2, 4.664E+1, 2.146E+1, 4.121E+1, 1.942E+1, 1.070E+1, 6.564   , 3.029   , 1.676   , 6.091E-1, 3.260E-1, 1.639E-1;...
    8.582E+3, 3.491E+3, 1.767E+3, 6.536E+2, 3.169E+2, 8.846E+2, 5.569E+2, 2.631E+2, 1.459E+2, 4.923E+1, 2.268E+1, 7.631   , 2.027E+1, 1.120E+1, 6.879   , 3.176   , 1.758   , 6.361E-1, 3.381E-1, 1.677E-1;...
    8.434E+3, 3.608E+3, 1.832E+3, 6.792E+2, 3.297E+2, 9.014E+2, 5.721E+2, 2.702E+2, 1.501E+2, 5.078E+1, 2.341E+1, 7.878   , 2.064E+1, 1.145E+1, 7.041   , 3.255   , 1.801   , 6.492E-1, 3.429E-1, 1.679E-1;...
    9.096E+3, 3.919E+3, 1.997E+3, 7.420E+2, 3.607E+2, 8.430E+2, 6.173E+2, 2.922E+2, 1.626E+2, 5.512E+1, 2.543E+1, 8.561   , 2.210E+1, 1.232E+1, 7.579   , 3.510   , 1.942   , 6.978E-1, 3.663E-1, 1.771E-1;...
    9.413E+3, 4.085E+3, 2.088E+3, 7.780E+2, 3.787E+2, 6.392E+2, 6.376E+2, 3.032E+2, 1.690E+2, 5.743E+1, 2.652E+1, 8.930   , 2.270E+1, 1.272E+1, 7.825   , 3.633   , 2.011   , 7.202E-1, 3.760E-1, 1.797E-1;...
    9.365E+3, 4.335E+3, 2.226E+3, 8.319E+2, 4.055E+2, 2.303E+2, 6.711E+2, 3.214E+2, 1.793E+2, 6.104E+1, 2.822E+1, 9.507   , 2.381E+1, 1.340E+1, 8.248   , 3.836   , 2.124   , 7.589E-1, 3.941E-1, 1.863E-1;...
    8.543E+3, 4.499E+3, 2.319E+3, 8.696E+2, 4.246E+2, 2.414E+2, 6.898E+2, 3.334E+2, 1.860E+2, 6.347E+1, 2.938E+1, 9.904   , 2.457E+1, 1.379E+1, 8.511   , 3.963   , 2.196   , 7.828E-1, 4.046E-1, 1.891E-1;...
    9.087E+3, 4.772E+3, 2.464E+3, 9.267E+2, 4.531E+2, 2.578E+2, 6.319E+2, 3.529E+2, 1.967E+2, 6.731E+1, 3.119E+1, 1.052E+1, 2.579E+1, 1.447E+1, 8.962   , 4.177   , 2.315   , 8.239E-1, 4.239E-1, 1.961E-1;...
    9.711E+3, 5.033E+3, 2.607E+3, 9.857E+2, 4.811E+2, 2.740E+2, 4.908E+2, 3.732E+2, 2.082E+2, 7.143E+1, 3.312E+1, 1.119E+1, 5.215   , 1.520E+1, 9.447   , 4.409   , 2.445   , 8.687E-1, 4.452E-1, 2.039E-1;...
    1.058E+4, 5.090E+3, 2.768E+3, 1.047E+3, 5.131E+2, 2.924E+2, 5.145E+2, 3.950E+2, 2.209E+2, 7.597E+1, 3.526E+1, 1.192E+1, 5.557   , 1.599E+1, 9.977   , 4.664   , 2.588   , 9.180E-1, 4.687E-1, 2.126E-1;...
    6.627E+3, 5.273E+3, 2.878E+3, 1.093E+3, 5.366E+2, 3.061E+2, 1.927E+2, 4.094E+2, 2.300E+2, 7.925E+1, 3.684E+1, 1.247E+1, 5.809   , 1.650E+1, 1.033E+1, 4.839   , 2.687   , 9.522E-1, 4.844E-1, 2.178E-1;...
    2.056E+3, 5.553E+3, 3.048E+3, 1.162E+3, 5.709E+2, 3.260E+2, 2.053E+2, 4.314E+2, 2.440E+2, 8.411E+1, 3.916E+1, 1.327E+1, 6.181   , 1.735E+1, 1.087E+1, 5.107   , 2.840   , 1.005   , 5.098E-1, 2.273E-1;...
    2.107E+3, 5.358E+3, 3.120E+3, 1.193E+3, 5.873E+2, 3.356E+2, 2.115E+2, 4.401E+2, 2.499E+2, 8.633E+1, 4.025E+1, 1.365E+1, 6.362   , 1.774E+1, 1.107E+1, 5.212   , 2.901   , 1.027   , 5.192E-1, 2.296E-1;...
    2.216E+3, 5.624E+3, 3.278E+3, 1.256E+3, 6.193E+2, 3.542E+2, 2.234E+2, 3.989E+2, 2.629E+2, 9.087E+1, 4.242E+1, 1.441E+1, 6.716   , 1.850E+1, 1.155E+1, 5.455   , 3.040   , 1.076   , 5.425E-1, 2.380E-1;...
    2.291E+3, 5.041E+3, 3.360E+3, 1.292E+3, 6.380E+2, 3.653E+2, 2.305E+2, 4.068E+2, 2.693E+2, 9.335E+1, 4.363E+1, 1.484E+1, 6.920   , 3.859   , 1.175E+1, 5.573   , 3.109   , 1.100   , 5.534E-1, 2.410E-1;...
    2.396E+3, 5.314E+3, 3.507E+3, 1.354E+3, 6.697E+2, 3.838E+2, 2.423E+2, 3.133E+2, 2.815E+2, 9.802E+1, 4.588E+1, 1.563E+1, 7.288   , 4.064   , 1.223E+1, 5.826   , 3.253   , 1.151   , 5.775E-1, 2.498E-1;...
    2.494E+3, 5.550E+3, 3.467E+3, 1.405E+3, 6.953E+2, 3.988E+2, 2.520E+2, 3.269E+2, 2.902E+2, 1.016E+2, 4.765E+1, 1.625E+1, 7.582   , 4.227   , 1.259E+1, 6.012   , 3.360   , 1.189   , 5.953E-1, 2.558E-1;...
    2.616E+3, 5.847E+3, 3.590E+3, 1.465E+3, 7.264E+2, 4.170E+2, 2.636E+2, 1.271E+2, 3.012E+2, 1.060E+2, 4.980E+1, 1.701E+1, 7.940   , 4.425   , 1.309E+1, 6.244   , 3.492   , 1.236   , 6.178E-1, 2.639E-1;...
    2.748E+3, 6.069E+3, 3.523E+3, 1.526E+3, 7.587E+2, 4.359E+2, 2.757E+2, 1.330E+2, 3.129E+2, 1.106E+2, 5.204E+1, 1.780E+1, 8.315   , 4.634   , 1.362E+1, 6.478   , 3.628   , 1.285   , 6.415E-1, 2.724E-1;...
    2.899E+3, 3.937E+3, 3.686E+3, 1.594E+3, 7.946E+2, 4.569E+2, 2.892E+2, 1.397E+2, 2.830E+2, 1.157E+2, 5.453E+1, 1.868E+1, 8.735   , 4.867   , 1.409E+1, 6.741   , 3.780   , 1.340   , 6.682E-1, 2.822E-1;...
    3.017E+3, 1.350E+3, 3.797E+3, 1.640E+3, 8.193E+2, 4.717E+2, 2.988E+2, 1.444E+2, 2.893E+2, 1.193E+2, 5.628E+1, 1.932E+1, 9.040   , 5.038   , 3.147   , 6.909   , 3.881   , 1.378   , 6.860E-1, 2.882E-1;...
    3.187E+3, 1.424E+3, 3.452E+3, 1.710E+3, 8.560E+2, 4.934E+2, 3.129E+2, 1.513E+2, 2.211E+2, 1.247E+2, 5.881E+1, 2.023E+1, 9.472   , 5.279   , 3.297   , 7.161   , 4.033   , 1.433   , 7.130E-1, 2.981E-1;...
    3.335E+3, 1.489E+3, 3.598E+3, 1.768E+3, 8.859E+2, 5.113E+2, 3.244E+2, 1.571E+2, 2.301E+2, 1.290E+2, 6.087E+1, 2.098E+1, 9.828   , 5.478   , 3.420   , 7.352   , 4.154   , 1.477   , 7.339E-1, 3.054E-1;...
    3.510E+3, 1.566E+3, 3.771E+3, 1.838E+3, 9.222E+2, 5.328E+2, 3.382E+2, 1.639E+2, 2.379E+2, 1.340E+2, 6.334E+1, 2.187E+1, 1.025E+1, 5.717   , 3.569   , 7.587   , 4.302   , 1.531   , 7.598E-1, 3.149E-1;...
    3.683E+3, 1.643E+3, 3.922E+3, 1.902E+3, 9.564E+2, 5.534E+2, 3.514E+2, 1.705E+2, 9.691E+1, 1.389E+2, 6.573E+1, 2.273E+1, 1.067E+1, 5.949   , 3.713   , 7.810   , 4.438   , 1.581   , 7.844E-1, 3.238E-1;...
    3.872E+3, 1.729E+3, 3.773E+3, 1.972E+3, 9.943E+2, 5.759E+2, 3.660E+2, 1.778E+2, 1.011E+2, 1.440E+2, 6.835E+1, 2.367E+1, 1.112E+1, 6.206   , 3.872   , 8.069   , 4.587   , 1.637   , 8.119E-1, 3.339E-1;...
    4.032E+3, 1.801E+3, 2.218E+3, 1.938E+3, 1.023E+3, 5.936E+2, 3.776E+2, 1.836E+2, 1.045E+2, 1.478E+2, 7.039E+1, 2.443E+1, 1.149E+1, 6.414   , 4.002   , 8.290   , 4.696   , 1.680   , 8.327E-1, 3.414E-1;...
    4.243E+3, 1.898E+3, 1.032E+3, 2.011E+3, 1.063E+3, 6.178E+2, 3.935E+2, 1.914E+2, 1.090E+2, 1.530E+2, 7.317E+1, 2.546E+1, 1.199E+1, 6.693   , 4.176   , 8.585   , 4.855   , 1.740   , 8.628E-1, 3.525E-1;...
    4.433E+3, 1.986E+3, 1.081E+3, 1.965E+3, 1.100E+3, 6.402E+2, 4.083E+2, 1.987E+2, 1.132E+2, 1.578E+2, 7.574E+1, 2.641E+1, 1.245E+1, 6.954   , 4.339   , 8.731   , 4.993   , 1.795   , 8.896E-1, 3.625E-1;...
    4.652E+3, 2.089E+3, 1.137E+3, 2.049E+3, 1.144E+3, 6.661E+2, 4.253E+2, 2.072E+2, 1.181E+2, 1.637E+2, 7.883E+1, 2.752E+1, 1.298E+1, 7.256   , 4.528   , 2.185   , 5.158   , 1.860   , 9.214E-1, 3.744E-1;...
    4.830E+3, 2.174E+3, 1.184E+3, 2.117E+3, 1.179E+3, 6.869E+2, 4.387E+2, 2.140E+2, 1.221E+2, 1.681E+2, 8.123E+1, 2.841E+1, 1.342E+1, 7.504   , 4.683   , 2.259   , 5.279   , 1.909   , 9.456E-1, 3.834E-1;...
    5.008E+3, 2.259E+3, 1.231E+3, 2.188E+3, 1.212E+3, 7.068E+2, 4.518E+2, 2.208E+2, 1.260E+2, 1.497E+2, 8.361E+1, 2.929E+1, 1.385E+1, 7.751   , 4.838   , 2.332   , 5.398   , 1.957   , 9.696E-1, 3.923E-1;...
    5.210E+3, 2.356E+3, 1.285E+3, 1.965E+3, 1.251E+3, 7.304E+2, 4.672E+2, 2.287E+2, 1.306E+2, 1.116E+2, 8.636E+1, 3.032E+1, 1.436E+1, 8.041   , 5.021   , 2.419   , 5.549   , 2.014   , 9.985E-1, 4.031E-1;...
    5.441E+3, 2.468E+3, 1.348E+3, 2.053E+3, 1.296E+3, 7.580E+2, 4.855E+2, 2.378E+2, 1.360E+2, 1.160E+2, 8.952E+1, 3.152E+1, 1.495E+1, 8.379   , 5.233   , 2.522   , 5.739   , 2.082   , 1.033   , 4.163E-1;...
    5.724E+3, 2.604E+3, 1.423E+3, 2.155E+3, 1.299E+3, 7.931E+2, 5.085E+2, 2.494E+2, 1.427E+2, 1.219E+2, 9.352E+1, 3.303E+1, 1.569E+1, 8.802   , 5.499   , 2.649   , 5.991   , 2.170   , 1.078   , 4.335E-1;...
    5.868E+3, 2.731E+3, 1.495E+3, 2.250E+3, 1.275E+3, 8.251E+2, 5.299E+2, 2.601E+2, 1.490E+2, 1.279E+2, 9.704E+1, 3.442E+1, 1.638E+1, 9.196   , 5.748   , 2.769   , 6.174   , 2.249   , 1.118   , 4.491E-1;...
    5.826E+3, 2.719E+3, 1.490E+3, 1.554E+3, 1.266E+3, 8.163E+2, 5.240E+2, 2.577E+2, 1.477E+2, 1.259E+2, 9.563E+1, 3.408E+1, 1.624E+1, 9.125   , 5.706   , 2.749   , 6.086   , 2.215   , 1.101   , 4.420E-1;...
    6.238E+3, 2.846E+3, 1.562E+3, 1.994E+3, 1.322E+3, 8.489E+2, 5.451E+2, 2.684E+2, 1.539E+2, 5.573E+1, 9.933E+1, 3.550E+1, 1.694E+1, 9.525   , 5.959   , 2.871   , 1.655   , 2.295   , 1.141   , 4.577E-1;...
    6.201E+3, 2.950E+3, 1.620E+3, 6.664E+2, 1.367E+3, 8.741E+2, 5.613E+2, 2.769E+2, 1.589E+2, 5.760E+1, 1.023E+2, 3.664E+1, 1.750E+1, 9.850   , 6.166   , 2.971   , 1.712   , 2.355   , 1.172   , 4.696E-1;...
    6.469E+3, 3.082E+3, 1.696E+3, 6.981E+2, 1.426E+3, 8.687E+2, 5.829E+2, 2.878E+2, 1.653E+2, 6.002E+1, 1.062E+2, 3.811E+1, 1.823E+1, 1.027E+1, 6.433   , 3.100   , 1.786   , 2.434   , 1.213   , 4.859E-1;...
    6.614E+3, 3.161E+3, 1.742E+3, 7.180E+2, 1.253E+3, 8.878E+2, 5.945E+2, 2.939E+2, 1.689E+2, 6.141E+1, 9.368E+1, 3.892E+1, 1.865E+1, 1.052E+1, 6.592   , 3.178   , 1.830   , 2.472   , 1.234   , 4.939E-1;...
    6.530E+3, 3.327E+3, 1.834E+3, 7.558E+2, 1.315E+3, 8.759E+2, 6.217E+2, 3.074E+2, 1.769E+2, 6.442E+1, 7.025E+1, 4.077E+1, 1.957E+1, 1.105E+1, 6.929   , 3.342   , 1.924   , 2.575   , 1.288   , 5.152E-1;...
    6.626E+3, 3.382E+3, 1.865E+3, 7.692E+2, 1.329E+3, 8.891E+2, 6.284E+2, 3.108E+2, 1.791E+2, 6.528E+1, 7.106E+1, 4.128E+1, 1.983E+1, 1.121E+1, 7.035   , 3.395   , 1.954   , 2.591   , 1.298   , 5.192E-1;...
    6.950E+3, 3.490E+3, 1.960E+3, 8.090E+2, 1.390E+3, 9.320E+2, 6.570E+2, 3.250E+2, 1.870E+2, 6.840E+1, 7.450E+1, 4.310E+1, 2.080E+1, 1.180E+1, 7.390   , 3.570   , 2.050   , 2.700   , 1.350   , 5.410E-1;...
    7.190E+3, 3.620E+3, 2.040E+3, 8.390E+2, 1.430E+3, 9.650E+2, 6.760E+2, 3.350E+2, 1.940E+2, 7.060E+1, 7.710E+1, 4.450E+1, 2.150E+1, 1.220E+1, 7.650   , 3.700   , 2.130   , 2.770   , 1.390   , 5.570E-1;...
    7.370E+3, 3.730E+3, 2.100E+3, 8.640E+2, 1.050E+3, 9.900E+2, 6.640E+2, 3.430E+2, 1.980E+2, 7.240E+1, 7.940E+1, 4.550E+1, 2.200E+1, 1.250E+1, 7.860E+0, 3.800E+0, 2.190E+0, 2.820E+0, 1.420E+0, 5.680E-1;...
    7.540E+3, 3.830E+3, 2.150E+3, 8.890E+2, 1.040E+3, 1.020E+3, 6.790E+2, 3.510E+2, 2.030E+2, 7.410E+1, 8.140E+1, 4.650E+1, 2.260E+1, 1.280E+1, 8.070E+0, 3.910E+0, 2.250E+0, 2.870E+0, 1.440E+0, 5.790E-1;...
    7.840E+3, 3.950E+3, 2.250E+3, 9.290E+2, 4.840E+2, 1.060E+3, 6.680E+2, 3.640E+2, 2.100E+2, 7.710E+1, 8.390E+1, 4.830E+1, 2.350E+1, 1.340E+1, 8.420E+0, 4.080E+0, 2.350E+0, 2.970E+0, 1.500E+0, 6.000E-1;...
    7.890E+3, 4.060E+3, 2.310E+3, 9.540E+2, 4.970E+2, 9.270E+2, 6.850E+2, 3.720E+2, 2.150E+2, 7.890E+1, 8.580E+1, 4.920E+1, 2.400E+1, 1.370E+1, 8.640E+0, 4.190E+0, 2.410E+0, 3.030E+0, 1.520E+0, 6.110E-1;...
    7.790E+3, 4.220E+3, 2.400E+3, 9.920E+2, 5.170E+2, 9.590E+2, 7.110E+2, 3.830E+2, 2.220E+2, 8.160E+1, 4.010E+1, 5.080E+1, 2.490E+1, 1.420E+1, 8.970E+0, 4.360E+0, 2.510E+0, 3.120E+0, 1.570E+0, 6.310E-1;...
    7.130E+3, 4.320E+3, 2.460E+3, 1.010E+3, 5.290E+2, 9.770E+2, 7.250E+2, 3.890E+2, 2.260E+2, 8.310E+1, 4.090E+1, 5.170E+1, 2.540E+1, 1.450E+1, 9.160E+0, 4.450E+0, 2.570E+0, 3.140E+0, 1.590E+0, 6.400E-1;...
    ];
%--------------------------------------------------------------------------
%% Hard-wire the table with description of each absorbtion edge
%   Z,  Energy(keV),    mac low,  mac high, meac low, meac high
%--------------------------------------------------------------------------
edges = [ ...
    11, 0.0010721*1000, 5.429E+2, 6.435E+3;...
    12, 0.001305 *1000, 4.530E+2, 5.444E+3;...
    13, 0.0015596*1000, 3.621E+2, 3.957E+3;...
    14, 0.0018389*1000, 3.092E+2, 3.192E+3;...
    15, 0.0021455*1000, 2.494E+2, 2.473E+3;...
    16, 0.002472 *1000, 2.168E+2, 2.070E+3;...
    17, 0.0028224*1000, 1.774E+2, 1.637E+3;...
    18, 0.0032029*1000, 1.424E+2, 1.275E+3;...
    19, 0.0036074*1000, 1.327E+2, 1.201E+3;...
    20, 0.0040381*1000, 1.187E+2, 1.023E+3;...
    21, 0.0044928*1000, 9.687E+1, 8.148E+2;...
    22, 0.0049664*1000, 8.380E+1, 6.878E+2;...
    23, 0.0054651*1000, 7.277E+1, 5.870E+2;...
    24, 0.0059892*1000, 6.574E+1, 5.160E+2;...
    25, 0.006539 *1000, 5.803E+1, 4.520E+2;...
    26, 0.007112 *1000, 5.319E+1, 4.076E+2;...
    27, 0.0077089*1000, 4.710E+1, 3.555E+2;...
    28, 0.0010081*1000, 9.654E+3, 1.099E+4;...
    28, 0.0083328*1000, 4.428E+1, 3.294E+2;...
    29, 0.0010961*1000, 8.242E+3, 9.347E+3;...
    29, 0.0089789*1000, 3.829E+1, 2.784E+2;...
    30, 0.0010197*1000, 1.484E+3, 3.804E+3;...
    30, 0.0010428*1000, 6.518E+3, 8.274E+3;...
    30, 0.0011936*1000, 7.371E+3, 8.396E+3;...
    30, 0.0096586*1000, 3.505E+1, 2.536E+2;...
    31, 0.0011154*1000, 1.312E+3, 3.990E+3;...
    31, 0.0011423*1000, 5.664E+3, 7.405E+3;...
    31, 0.0012977*1000, 6.358E+3, 7.206E+3;...
    31, 0.0103671*1000, 3.099E+1, 2.214E+2;...
    32, 0.0012167*1000, 1.190E+3, 4.389E+3;...
    32, 0.0012478*1000, 4.974E+3, 6.698E+3;...
    32, 0.0014143*1000, 5.554E+3, 6.287E+3;...
    32, 0.0111031*1000, 2.811E+1, 1.981E+2;...
    33, 0.0013231*1000, 1.092E+3, 4.513E+3;...
    33, 0.0013586*1000, 4.452E+3, 6.093E+3;...
    33, 0.0015265*1000, 4.997E+3, 5.653E+3;...
    33, 0.0118667*1000, 2.577E+1, 1.792E+2;...
    34, 0.0014358*1000, 9.814E+2, 4.347E+3;...
    34, 0.0014762*1000, 3.907E+3, 5.186E+3;...
    34, 0.0016539*1000, 4.342E+3, 4.915E+3;...
    34, 0.0126578*1000, 2.318E+1, 1.589E+2;...
    35, 0.0015499*1000, 9.255E+2, 4.289E+3;...
    35, 0.001596 *1000, 3.587E+3, 5.097E+3;...
    35, 0.001782 *1000, 3.969E+3, 4.495E+3;...
    35, 0.0134737*1000, 2.176E+1, 1.471E+2;...
    36, 0.0016749*1000, 8.361E+2, 3.909E+3;...
    36, 0.0017272*1000, 3.166E+3, 4.566E+3;...
    36, 0.001921 *1000, 3.482E+3, 3.948E+3;...
    36, 0.0143256*1000, 1.971E+1, 1.313E+2;...
    37, 0.0018044*1000, 7.782E+2, 3.096E+3;...
    37, 0.0018639*1000, 2.861E+3, 3.957E+3;...
    37, 0.0020651*1000, 3.153E+3, 3.606E+3;...
    37, 0.0151997*1000, 1.842E+1, 1.208E+2;...
    38, 0.0019396*1000, 7.207E+2, 2.864E+3;...
    38, 0.0020068*1000, 2.571E+3, 3.577E+3;...
    38, 0.0022163*1000, 2.842E+3, 3.241E+3;...
    38, 0.0161046*1000, 1.714E+1, 1.108E+2;...
    39, 0.00208  *1000, 6.738E+2, 2.627E+3;...
    39, 0.0021555*1000, 2.342E+3, 3.264E+3;...
    39, 0.0023725*1000, 2.597E+3, 2.962E+3;...
    39, 0.0170384*1000, 1.612E+1, 1.029E+2;...
    40, 0.0022223*1000, 6.258E+2, 2.392E+3;...
    40, 0.0023067*1000, 2.120E+3, 2.953E+3;...
    40, 0.0025316*1000, 2.359E+3, 2.691E+3;...
    40, 0.0179976*1000, 1.501E+1, 9.470E+1;...
    41, 0.0023705*1000, 5.844E+2, 2.181E+3;...
    41, 0.0024647*1000, 1.935E+3, 2.694E+3;...
    41, 0.0026977*1000, 2.161E+3, 2.470E+3;...
    41, 0.0189856*1000, 1.409E+1, 8.784E+1;...
    42, 0.0025202*1000, 5.415E+2, 1.979E+3;...
    42, 0.0026251*1000, 1.750E+3, 2.433E+3;...
    42, 0.0028655*1000, 1.961E+3, 2.243E+3;...
    42, 0.0199995*1000, 1.308E+1, 8.055E+1;...
    43, 0.0026769*1000, 5.072E+2, 1.812E+3;...
    43, 0.0027932*1000, 1.602E+3, 2.223E+3;...
    43, 0.0030425*1000, 1.800E+3, 2.059E+3;...
    43, 0.021044 *1000, 1.229E+1, 7.481E+1;...
    44, 0.0028379*1000, 4.704E+2, 1.644E+3;...
    44, 0.0029669*1000, 1.452E+3, 2.317E+3;...
    44, 0.003224 *1000, 1.638E+3, 1.874E+3;...
    44, 0.0221172*1000, 1.143E+1, 6.876E+1;...
    45, 0.0030038*1000, 4.427E+2, 1.513E+3;...
    45, 0.0031461*1000, 1.337E+3, 1.847E+3;...
    45, 0.0034119*1000, 1.512E+3, 1.731E+3;...
    45, 0.0232199*1000, 1.079E+1, 6.414E+1;...
    46, 0.0031733*1000, 4.106E+2, 1.355E+3;...
    46, 0.0033303*1000, 1.215E+3, 1.664E+3;...
    46, 0.0036043*1000, 1.379E+3, 1.582E+3;...
    46, 0.0243503*1000, 1.003E+1, 5.898E+1;...
    47, 0.0033511*1000, 3.887E+2, 1.274E+3;...
    47, 0.0035237*1000, 1.126E+3, 1.547E+3;...
    47, 0.0038058*1000, 1.282E+3, 1.468E+3;...
    47, 0.025514 *1000, 9.527   , 5.539E+1;...
    48, 0.0035375*1000, 3.575E+2, 1.152E+3;...
    48, 0.003727 *1000, 1.013E+3, 1.389E+3;...
    48, 0.004018 *1000, 1.157E+3, 1.324E+3;...
    48, 0.0267112*1000, 8.809   , 5.065E+1;...
    49, 0.0037301*1000, 3.356E+2, 1.046E+3;...
    49, 0.003938 *1000, 9.313E+2, 1.261E+3;...
    49, 0.0042375*1000, 1.066E+3, 1.223E+3;...
    49, 0.0279399*1000, 8.316   , 4.733E+1;...
    50, 0.0039288*1000, 3.114E+2, 9.285E+2;...
    50, 0.0041561*1000, 8.469E+2, 1.145E+3;...
    50, 0.0044647*1000, 9.712E+2, 1.117E+3;...
    50, 0.0292001*1000, 7.760   , 4.360E+1;...
    51, 0.0041322*1000, 2.918E+2, 8.691E+2;...
    51, 0.0043804*1000, 7.776E+2, 1.050E+3;...
    51, 0.0046983*1000, 8.939E+2, 1.029E+3;...
    51, 0.0304912*1000, 7.307   , 4.073E+1;...
    52, 0.001006 *1000, 8.326E+3, 8.684E+3;...
    52, 0.0043414*1000, 2.678E+2, 7.882E+2;...
    52, 0.004612 *1000, 6.995E+2, 9.445E+2;...
    52, 0.0049392*1000, 8.062E+2, 9.292E+2;...
    52, 0.0318138*1000, 6.738   , 3.719E+1;...
    53, 0.0010721*1000, 7.863E+3, 8.198E+3;...
    53, 0.0045571*1000, 2.592E+2, 7.550E+2;...
    53, 0.0048521*1000, 6.636E+2, 8.943E+2;...
    53, 0.0051881*1000, 7.665E+2, 8.837E+2;...
    53, 0.0331694*1000, 6.553   , 3.582E+1;...
    54, 0.001149 *1000, 7.035E+3, 7.338E+3;...
    54, 0.0047822*1000, 2.408E+2, 6.941E+2;...
    54, 0.0051037*1000, 6.044E+2, 8.181E+2;...
    54, 0.0054528*1000, 6.991E+2, 8.064E+2;...
    54, 0.0345614*1000, 6.129   , 3.316E+1;...
    55, 0.001065 *1000, 8.214E+3, 8.685E+3;...
    55, 0.0012171*1000, 6.584E+3, 6.888E+3;...
    55, 0.0050119*1000, 2.290E+2, 6.674E+2;...
    55, 0.0053594*1000, 5.645E+2, 7.692E+2;...
    55, 0.0057143*1000, 6.556E+2, 7.547E+2;...
    55, 0.0359846*1000, 5.863   , 3.143E+1;... % Stop at caesium
    ];
%% Initialize variables
elems  = z(:);
fracs = fracs ./ sum(fracs); % normalize fractions
nData = size(mac, 1);
nelem = length(elems);
A = cell(1, nelem);
B = cell(1, nelem);
%% Main Loop
for i = 1:nelem
    elem = round(elems(i));

    if (ischar(elem) || any(elem<1) || any(elem>nData))
        error(['Error in PhotonAttenuationQ function: Z number outside [1, 100] range: ', num2str(elem)]);
    end
    x = energy';
    y = mac (elem, :)';
    if (elem>10)      % if absorbtion edges are present for this element
        ed = edges(edges(:, 1)==elem, :); % check if 'element' has edges
        nEdge = size(ed, 1);
        e  = ed(:, 2)';    % energy of absorbtion edges
        d  = 4*eps(e);     % create offset to create 2 different energies for upper and lower end of the edge
        xx = [e-d; e+d];   % energies
        yy = ed(:, 3:4)';  % mac values
        w  = [zeros(size(x)); ones(2*nEdge, 1)]; % this is array that will help keep track of edges
        x  = log([x; xx(:)]);
        y  = log([y; yy(:)]);
        [x, ix] = sort(x);  % merge absorbtion edge data with other data
        y  = y(ix, :);
        w  = w(ix, :); % array with 0 for 'grid' points and 1's for absorbtion edge points
        w  = (convn(w, [1; 1; 1],  'same')>0); % neighbors of edges will be marked with 1's too
        b  = griddedInterpolant(x, [y, w],  'linear'); % merge inputs for speed
        a  = griddedInterpolant(x,  y,      'pchip');
        A{i} = a; B{i} = b;
    else % if there are no absorbtion edges than life is easy
        a = griddedInterpolant(log(x),  log(y),  'pchip');
        A{i} = a; B{i} = 0;
    end
end
%% Create function to return attenuation coefficients
att_fun = @get_attenuation;
    function att = get_attenuation(nrj)
        att = 0;
        if nrj < 0.9|| nrj > 300
            warning('photon_attenuation:wrongEnergy',...
                'photon_attenuation function: energy is outside of the recomended range from 1 keV to 1 MeV');
        end
        nrj = log(nrj);
        % Do interpolation
        for ei = 1:nelem
            a = A{ei}(nrj); 
            if round(elems(ei)) > 10
                b  = B{ei}(nrj);
                v  = b(:, 2);
                b  = b(:, 1);
                a  = a.*(1-v) + b.*v; % smoothly merge curves using linear near edges and cubic otherwise
            end
            att = att + exp(a) * fracs(ei);
        end
        att = att * density; %Convert from cm^2/g to cm^-1
    end

end

%{
Most of this code has the following license:
Copyright (c) 2016, Jaroslaw Tuszynski
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%}
