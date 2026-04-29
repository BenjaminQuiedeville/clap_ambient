using DSP, WAV

function stretch(input_filename, stretch_factor, resolution_sec)

    input_file, samplerate, _, _ = WAV.wavread(input_filename)

    window_size = trunc(Int, resolution_sec * samplerate)
    window_size = trunc(Int, window_size/2) * 2

    step = trunc(Int, window_size / (2*stretch_factor))

    input_signal = @view input_file[:, 1]
    output = zeros(length(input_signal) * stretch_factor)

    # @infiltrate
    in_index = 1
    out_index = 1
    window_function = DSP.hanning(window_size)

    temp = (1+sqrt(0.5))*0.5
    am_removal_function =  temp .- (1.0 - temp) .* cos.((1:Int(window_size/2)) .* 2pi/(window_size/2))

    while (in_index + window_size) <= length(input_signal)

        window = input_signal[in_index:(in_index+window_size-1)]

        dft = DSP.rfft(window .* window_function)
        dft[:] .= abs.(dft) .* exp.(im .* 2π .* rand(Float64, length(dft)))
        result = DSP.irfft(dft, window_size)
        output[out_index:(out_index+window_size-1)] .+= result .* window_function
        output[out_index:(out_index+Int(window_size/2))-1] .*= am_removal_function

        in_index += step
        out_index += div(window_size,2)
    end
    
    wavwrite(output, "paul_stretch_output.wav", Fs = samplerate)
    return output
end

