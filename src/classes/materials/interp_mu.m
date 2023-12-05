function mu = interp_mu(energies, mus, energy)
    if energy < energies(1) || energy > energies(end)
        warning('Energy out of data range for material, extrapolation likely to be inaccurate');
    end
    mu = interp1(energies, mus, energy, 'pchip');
end
