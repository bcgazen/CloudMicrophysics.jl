import Test as TT

import Thermodynamics as TD
import CloudMicrophysics as CM
import CLIMAParameters as CP

const CMT = CM.CommonTypes
const CMI = CM.HetIceNucleation
const ArizonaTestDust = CMT.ArizonaTestDustType()
const DesertDust = CMT.DesertDustType()

include(joinpath(pkgdir(CM), "test", "create_parameters.jl"))

function test_dust_activation(FT)
    toml_dict = CP.create_toml_dict(FT; dict_type = "alias")
    prs = cloud_microphysics_parameters(toml_dict)

    TT.@testset "dust_activation" begin

        T_warm = FT(250)
        T_cold = FT(210)
        Si_low = FT(1.01)
        Si_med = FT(1.2)
        Si_hgh = FT(1.34)
        Si_too_hgh = FT(1.5)

        # No activation below critical supersaturation
        for dust in [ArizonaTestDust, DesertDust]
            for T in [T_warm, T_cold]
                TT.@test CMI.dust_activated_number_fraction(Si_low, T, dust) ==
                         FT(0)
            end
        end

        # Activate more in cold temperatures and higher supersaturations
        for dust in [ArizonaTestDust, DesertDust]
            TT.@test CMI.dust_activated_number_fraction(Si_hgh, T_warm, dust) >
                     CMI.dust_activated_number_fraction(Si_med, T_warm, dust)
            TT.@test CMI.dust_activated_number_fraction(Si_med, T_cold, dust) >
                     CMI.dust_activated_number_fraction(Si_med, T_warm, dust)
        end

        for dust in [ArizonaTestDust, DesertDust]
            for T in [T_warm, T_cold]
                TT.@test CMI.dust_activated_number_fraction(
                    Si_too_hgh,
                    T,
                    dust,
                ) == FT(0)
            end
        end
    end
end

println("")
println("Testing Float64")
benchmark_test(Float64)

println("")
println("Testing Float32")
benchmark_test(Float32)
