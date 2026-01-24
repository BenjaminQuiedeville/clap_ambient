{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 9,
            "minor": 1,
            "revision": 2,
            "architecture": "x64",
            "modernui": 1
        },
        "classnamespace": "box",
        "rect": [ 34.0, 77.0, 1852.0, 939.0 ],
        "subpatcher_template": "empty_mixer",
        "boxes": [
            {
                "box": {
                    "autosave": 1,
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "id": "obj-8",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 8,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "signal", "signal", "", "list", "int", "", "", "" ],
                    "patching_rect": [ 77.0, 255.0, 300.0, 100.0 ],
                    "save": [ "#N", "vst~", "loaduniqueid", 0, "C74_VST3:/AmpModeler", ";" ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_invisible": 1,
                            "parameter_longname": "vst~[1]",
                            "parameter_modmode": 0,
                            "parameter_shortname": "vst~[1]",
                            "parameter_type": 3
                        }
                    },
                    "saved_object_attributes": {
                        "parameter_enable": 1,
                        "parameter_mappable": 0
                    },
                    "snapshot": {
                        "filetype": "C74Snapshot",
                        "version": 2,
                        "minorversion": 0,
                        "name": "snapshotlist",
                        "origin": "vst~",
                        "type": "list",
                        "subtype": "Undefined",
                        "embed": 1,
                        "snapshot": {
                            "pluginname": "AmpModeler.vst3info",
                            "plugindisplayname": "AmpModeler",
                            "pluginsavedname": "",
                            "pluginsaveduniqueid": -1908487325,
                            "version": 1,
                            "isbank": 0,
                            "isbase64": 1,
                            "sliderorder": [],
                            "slidervisibility": [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
                            "blob": "3713.VMjLgfmC...O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9HyMv.iKPUDahcFLwHlKt.kK23RUPIUQTMkKDYlKuEkQtDjcPEjPIUkTGcFQUUVSTAETAY1XmcmUisVPP4RRP4hKt3hKt3hKtbyJt3BUAkTUP0TPP4hPpYTVtPDTBUDSDIUPzn1TEcGQtDSQFEFLUYjKAolKA4hKt3hKt3hKH4BQt.UQpQUPvPjKAgDTZoVPP4BTTYGTHUjZS4TUDMUYMo2TNkEURcTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYmPEQEUTUVQ5AEUqoVUEEjYic1cVM1ZAAkKIAkKt3hKt3hKt3xMq3hKTETRUAUSAAkKBolQY4BQPMTQhQETTUkdWETSDUURYUUTtf0UXIWUWkkKDAkPD4hKt3hKt3hKtrxSt3RUPIUQTMkKDYlKuEkQtDjdPEzQEQTUEgSUPQUTUA0PyQjKwTjQgASUF4RPp4RPt3hKt3hKt3hcqLjKPUjZTEDLD4RPHAkVpEDTt3DU1EUPQUUTkkTUQwTUTA0TUQjKwTjQgASUF4RPp4RPt3hKt3hKt3BctPjKPUjZTEDLD4RPHAkVpEDTtzDU1EUPQUUTkkTUQQUUqQkSAY1XmcmUisVPP4RRP4hKt3hKt3hKt3hKt3BUAkTUP0TPP4hPpYTVtPDTCUjXTAEUUo2UTclZTUTSEIkKXcEVxU0UY4BQPIDQt3hKt3hKt3xREYmKtTETRUDUS4BQl4xaQYjKAcCTAgzZ5EER3.CTUEELWYTRUEUTAY1XmcmUisVPP4RRP4hKt3hKt3hYynmKA4BUAkTUP0TPP4hPpYTVtPjcBUjYTI0Qmo2UFkTUQEUPlM1Y2Y0XqEDTtjDTt3hKt3BRt3hds4RPtPUPIUETMEDTtHjZFkkKDYmPEYFURczY5c0QEQkTNEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQtHTQlQkTGcldWEUPlM1Y2Y0XqEDTtjDTt3hKt3xLqrxJxrhKtPUPIUETMEDTtHjZFkkKDAEQEYFURczY5c0TmQUTLkkdWYTRUEUTAY1XmcmUisVPP4RRP4hKt3hKt3hYynmKA4BUAkTUP0TPP4hPpYTVtPDTDUjYTI0Qmo2UScFUQwTV5c0QEQkTNEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQlMTQpo1TPUUQUUVVTIESQUUTREjYic1cVM1ZAAkKIAkKt3hKtLyJq7jUtDjKTETRUAUSAAkKBolQY4BQtLTQpo1TPUUQUU1XTAURzPjKwTjQgASUF4RPp4RPt3hKt3hKt3hKt3hKPUjZTEDLD4RPHAkVpEDTtrDUPIkT3TETCEUURYUUD4RLEYTXvTkQtDjZtDjKt3hKt3hKtX2JC4BTEoFUAACQtDDRPokZAAkKMQkKS8zXUMURQo2UFkTUQEUPlM1Y2Y0XqEDTtjDTt3hKt3BRt3BTZ4RPtPUPIUETMEDTtHjZFkkKDA0PEYmdScELTIEQ3.STAslZS4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RPtAUPLgidU0zZDEUYEUjKwTjQgASUF4RPp4RPt3hKtX1JqrRYqLjKPUjZTEDLD4RPHAkVpEDTt3DUtL0SiAyUCUUQUUVVpQUQEUjKwTjQgASUF4RPp4RPt3hKt3hKt3hZtPjKPUjZTEDLD4RPHAkVpEDTt.EUtL0SiAyUScFUQwTV5ckQIUUTQEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RRtDjKTETRUAUSAAkKBolQY4BQtPTQ1o2TWgCLTgTUDMkQ3.STAslZS4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPMUjdTQUUpQUYYAyTLUUUSUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYlPEoGURQDNqEkTUQEUtf0UXIWUWkkKDAkPD4hKt3hKt3hYWgDTt3RUPIUQTMkKDYlKuEkQtDjaPETSqQTTkMFUPkDMD4RLEYTXvTkQtDjZtDjKt3hKt3hKt3hKt3BTEoFUAACQtDDRPokZAAkKGQETSkTT5cUTAY1XmcmUisVPP4RRP4hKt3hKyrxJqHyJt3BUAkTUP0TPP4hPpYTVtPjcCUjKqQUQEQ0TPgSUPMTTUIkUUQjKwTjQgASUF4RPp4RPt3hKt3hKt3hcqLjKPUjZTEDLD4RPHAkVpEDTtzDUtPkTUQETMEDLWcTQTIkSAY1XmcmUisVPP4RRP4hKt3hKt3hKtTjKA4BUAkTUP0TPP4hPpYTVtPjcCUjKqQUQEQ0TPgyZU8zcTUUSUQjKwTjQgASUF4RPp4RPt3hKt3hKt3hKt3hKPUjZTEDLD4RPHAkVpEDTtnDUtPkTUoGUEQidPUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKE4RPtPUPIUETMEDTtHjZFkkKDYmPEgTUQMENpMUPznGTEEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDjKTETRUAUSAAkKBolQY4BQlMTQLACTEUDUSUTRvbkQIUUTQEjYic1cVM1ZAAkKIAkKt3hKt3hKtTzZtDjKTETRUAUSAAkKBolQY4BQPQTQLACTRUEUP0TUpQUYEQ0TOU0ZSQUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDA0PEwTQUEzXTEkc2rFTIUjdT4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPSEUUPcTUDwTYIQkUPUjdTMUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKE4xPtPUPIUETMEDTtHjZFkkKDYmPEwTQUEzXTEkc2TzTPEjYic1cVM1ZAAkKIAkKt3hKt3hKtHyctDjKTETRUAUSAAkKBolQY4BQtTTQLUTUAMFUQc2MUAEUQUUTNUUUPQ0Z5MkSAY1XmcmUisVPP4RRP4hKt3hK1wTdLYyJt3BUAkTUP0TPP4hPpYTVtPDTCUDSEUUPiQUT2cyZPkTQ5QkKXcEVxU0UY4BQPIDQt3hKt3BVrkEa27jKtTETRUDUS4BQl4xaQYjKAcCTAMUTUA0QUQESkkDUVAUQ5Q0TAY1XmcmUisVPP4RRP4hKt3hKt3hKtPjKC4BUAkTUP0TPP4hPpYTVtPjcBUDSEUUPiQUT2cSQSAUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hL24RPtPUPIUETMEDTtHjZFkkKD4RQEwTQUEzXTEEd2TETTEUUQ4TUUAEUqo2TNEjYic1cVM1ZAAkKIAkKt3hKtfTdLk2Lq3hKTETRUAUSAAkKBolQY4BQPMTQLUTUAMFUQg2MqAUREoGUtf0UXIWUWkkKDAkPD4hKt3hK3wTdLgySt3RUPIUQTMkKDYlKuEkQtDzMPEzTQUETGUkZLUVRTYETEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQ1ITQLUTUAMFUQg2MEMETAY1XmcmUisVPP4RRP4hKt3hKt3hKxbmKA4BUAkTUP0TPP4hPpYTVtPjKEUDSEUUPiQUT4cSUPQUTUEkSUUETTsldS4TPlM1Y2Y0XqEDTtjDTt3hKt3BR4wTdyrhKtPUPIUETMEDTtHjZFkkKDA0PEwTQUEzXTEUd2rFTIUjdT4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPSEUUPcTU5wTYIQkUPUjdTMUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKF4xPtPUPIUETMEDTtHjZFkkKDYmPEwTQUEzXTEUd2TzTPEjYic1cVM1ZAAkKIAkKt3hKt3hKtHyctDjKTETRUAUSAAkKBolQY4BQPMTQLUTUAMFUQo2MqAUREoGUtf0UXIWUWkkKDAkPD4hKt3hKt3hKt3hKt3RUPIUQTMkKDYlKuEkQtDzMPEzTQUETGUEQMUVRTYETEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hQtLjKTETRUAUSAAkKBolQY4BQ1ITQLUTUAMFUQo2MEMETAY1XmcmUisVPP4RRP4hKt3hKt3hKxbmKA4BUAkTUP0TPP4hPpYTVtPjcAUDTUI0QmQTUtf0UXIWUWkkKDAkPD4hKt3hKt3hKPIDTt3RUPIUQTMkKDYlKuEkQtDDRQEDU3n1TE0TQUETS5IUYEoGTTslZUUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hK2rhKtPUPIUETMEDTtHjZFkkKDYmPEAELS4TU5ckPEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDjKTETRUAUSAAkKBolQY4BQlITQPAyTNUkdW0zZDEkKXcEVxU0UY4BQPIDQt3hKt3hKt3BTAAkKtTETRUDUS4BQl4xaQYjKAYGTAQENpMUQ3T0TOEEUQwTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYmPEAELS4TU5cEUIUUTBEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDDTRIENEQUPQUjTSEDTtHjZpQ0ct.kKBQkKtjTRqwjKDYlKE4hKt3hKt3hKt3hKt3hYRUUSTEETIckVwTjQisVTTgkdEYjKAQjYPQSPWgUdMcjKAQjct3hdA4hKt3hKt3hKtnTUv.UQAslXuk0UXoWUFE0YQcEV77RRC8Vav8lak4Fc9vyKVMEUy.Ea0cVZtMEcgQWY9.."
                        },
                        "snapshotlist": {
                            "current_snapshot": 0,
                            "entries": [
                                {
                                    "filetype": "C74Snapshot",
                                    "version": 2,
                                    "minorversion": 0,
                                    "name": "AmpModeler",
                                    "origin": "AmpModeler.vst3info",
                                    "type": "VST3",
                                    "subtype": "AudioEffect",
                                    "embed": 0,
                                    "snapshot": {
                                        "pluginname": "AmpModeler.vst3info",
                                        "plugindisplayname": "AmpModeler",
                                        "pluginsavedname": "",
                                        "pluginsaveduniqueid": -1908487325,
                                        "version": 1,
                                        "isbank": 0,
                                        "isbase64": 1,
                                        "sliderorder": [],
                                        "slidervisibility": [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
                                        "blob": "3713.VMjLgfmC...O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9HyMv.iKPUDahcFLwHlKt.kK23RUPIUQTMkKDYlKuEkQtDjcPEjPIUkTGcFQUUVSTAETAY1XmcmUisVPP4RRP4hKt3hKt3hKtbyJt3BUAkTUP0TPP4hPpYTVtPDTBUDSDIUPzn1TEcGQtDSQFEFLUYjKAolKA4hKt3hKt3hKH4BQt.UQpQUPvPjKAgDTZoVPP4BTTYGTHUjZS4TUDMUYMo2TNkEURcTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYmPEQEUTUVQ5AEUqoVUEEjYic1cVM1ZAAkKIAkKt3hKt3hKt3xMq3hKTETRUAUSAAkKBolQY4BQPMTQhQETTUkdWETSDUURYUUTtf0UXIWUWkkKDAkPD4hKt3hKt3hKtrxSt3RUPIUQTMkKDYlKuEkQtDjdPEzQEQTUEgSUPQUTUA0PyQjKwTjQgASUF4RPp4RPt3hKt3hKt3hcqLjKPUjZTEDLD4RPHAkVpEDTt3DU1EUPQUUTkkTUQwTUTA0TUQjKwTjQgASUF4RPp4RPt3hKt3hKt3BctPjKPUjZTEDLD4RPHAkVpEDTtzDU1EUPQUUTkkTUQQUUqQkSAY1XmcmUisVPP4RRP4hKt3hKt3hKt3hKt3BUAkTUP0TPP4hPpYTVtPDTCUjXTAEUUo2UTclZTUTSEIkKXcEVxU0UY4BQPIDQt3hKt3hKt3xREYmKtTETRUDUS4BQl4xaQYjKAcCTAgzZ5EER3.CTUEELWYTRUEUTAY1XmcmUisVPP4RRP4hKt3hKt3hYynmKA4BUAkTUP0TPP4hPpYTVtPjcBUjYTI0Qmo2UFkTUQEUPlM1Y2Y0XqEDTtjDTt3hKt3BRt3hds4RPtPUPIUETMEDTtHjZFkkKDYmPEYFURczY5c0QEQkTNEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQtHTQlQkTGcldWEUPlM1Y2Y0XqEDTtjDTt3hKt3xLqrxJxrhKtPUPIUETMEDTtHjZFkkKDAEQEYFURczY5c0TmQUTLkkdWYTRUEUTAY1XmcmUisVPP4RRP4hKt3hKt3hYynmKA4BUAkTUP0TPP4hPpYTVtPDTDUjYTI0Qmo2UScFUQwTV5c0QEQkTNEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQlMTQpo1TPUUQUUVVTIESQUUTREjYic1cVM1ZAAkKIAkKt3hKtLyJq7jUtDjKTETRUAUSAAkKBolQY4BQtLTQpo1TPUUQUU1XTAURzPjKwTjQgASUF4RPp4RPt3hKt3hKt3hKt3hKPUjZTEDLD4RPHAkVpEDTtrDUPIkT3TETCEUURYUUD4RLEYTXvTkQtDjZtDjKt3hKt3hKtX2JC4BTEoFUAACQtDDRPokZAAkKMQkKS8zXUMURQo2UFkTUQEUPlM1Y2Y0XqEDTtjDTt3hKt3BRt3BTZ4RPtPUPIUETMEDTtHjZFkkKDA0PEYmdScELTIEQ3.STAslZS4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RPtAUPLgidU0zZDEUYEUjKwTjQgASUF4RPp4RPt3hKtX1JqrRYqLjKPUjZTEDLD4RPHAkVpEDTt3DUtL0SiAyUCUUQUUVVpQUQEUjKwTjQgASUF4RPp4RPt3hKt3hKt3hZtPjKPUjZTEDLD4RPHAkVpEDTt.EUtL0SiAyUScFUQwTV5ckQIUUTQEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RRtDjKTETRUAUSAAkKBolQY4BQtPTQ1o2TWgCLTgTUDMkQ3.STAslZS4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPMUjdTQUUpQUYYAyTLUUUSUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYlPEoGURQDNqEkTUQEUtf0UXIWUWkkKDAkPD4hKt3hKt3hYWgDTt3RUPIUQTMkKDYlKuEkQtDjaPETSqQTTkMFUPkDMD4RLEYTXvTkQtDjZtDjKt3hKt3hKt3hKt3BTEoFUAACQtDDRPokZAAkKGQETSkTT5cUTAY1XmcmUisVPP4RRP4hKt3hKyrxJqHyJt3BUAkTUP0TPP4hPpYTVtPjcCUjKqQUQEQ0TPgSUPMTTUIkUUQjKwTjQgASUF4RPp4RPt3hKt3hKt3hcqLjKPUjZTEDLD4RPHAkVpEDTtzDUtPkTUQETMEDLWcTQTIkSAY1XmcmUisVPP4RRP4hKt3hKt3hKtTjKA4BUAkTUP0TPP4hPpYTVtPjcCUjKqQUQEQ0TPgyZU8zcTUUSUQjKwTjQgASUF4RPp4RPt3hKt3hKt3hKt3hKPUjZTEDLD4RPHAkVpEDTtnDUtPkTUoGUEQidPUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKE4RPtPUPIUETMEDTtHjZFkkKDYmPEgTUQMENpMUPznGTEEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDjKTETRUAUSAAkKBolQY4BQlMTQLACTEUDUSUTRvbkQIUUTQEjYic1cVM1ZAAkKIAkKt3hKt3hKtTzZtDjKTETRUAUSAAkKBolQY4BQPQTQLACTRUEUP0TUpQUYEQ0TOU0ZSQUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDA0PEwTQUEzXTEkc2rFTIUjdT4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPSEUUPcTUDwTYIQkUPUjdTMUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKE4xPtPUPIUETMEDTtHjZFkkKDYmPEwTQUEzXTEkc2TzTPEjYic1cVM1ZAAkKIAkKt3hKt3hKtHyctDjKTETRUAUSAAkKBolQY4BQtTTQLUTUAMFUQc2MUAEUQUUTNUUUPQ0Z5MkSAY1XmcmUisVPP4RRP4hKt3hK1wTdLYyJt3BUAkTUP0TPP4hPpYTVtPDTCUDSEUUPiQUT2cyZPkTQ5QkKXcEVxU0UY4BQPIDQt3hKt3BVrkEa27jKtTETRUDUS4BQl4xaQYjKAcCTAMUTUA0QUQESkkDUVAUQ5Q0TAY1XmcmUisVPP4RRP4hKt3hKt3hKtPjKC4BUAkTUP0TPP4hPpYTVtPjcBUDSEUUPiQUT2cSQSAUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hL24RPtPUPIUETMEDTtHjZFkkKD4RQEwTQUEzXTEEd2TETTEUUQ4TUUAEUqo2TNEjYic1cVM1ZAAkKIAkKt3hKtfTdLk2Lq3hKTETRUAUSAAkKBolQY4BQPMTQLUTUAMFUQg2MqAUREoGUtf0UXIWUWkkKDAkPD4hKt3hK3wTdLgySt3RUPIUQTMkKDYlKuEkQtDzMPEzTQUETGUkZLUVRTYETEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hKt3hKTETRUAUSAAkKBolQY4BQ1ITQLUTUAMFUQg2MEMETAY1XmcmUisVPP4RRP4hKt3hKt3hKxbmKA4BUAkTUP0TPP4hPpYTVtPjKEUDSEUUPiQUT4cSUPQUTUEkSUUETTsldS4TPlM1Y2Y0XqEDTtjDTt3hKt3BR4wTdyrhKtPUPIUETMEDTtHjZFkkKDA0PEwTQUEzXTEUd2rFTIUjdT4BVWgkbUcUVtPDTBQjKt3hKt3hKt3hKt3hKUAkTEQ0TtPjYt7VTF4RP2.UPSEUUPcTU5wTYIQkUPUjdTMUPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKF4xPtPUPIUETMEDTtHjZFkkKDYmPEwTQUEzXTEUd2TzTPEjYic1cVM1ZAAkKIAkKt3hKt3hKtHyctDjKTETRUAUSAAkKBolQY4BQPMTQLUTUAMFUQo2MqAUREoGUtf0UXIWUWkkKDAkPD4hKt3hKt3hKt3hKt3RUPIUQTMkKDYlKuEkQtDzMPEzTQUETGUEQMUVRTYETEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3hQtLjKTETRUAUSAAkKBolQY4BQ1ITQLUTUAMFUQo2MEMETAY1XmcmUisVPP4RRP4hKt3hKt3hKxbmKA4BUAkTUP0TPP4hPpYTVtPjcAUDTUI0QmQTUtf0UXIWUWkkKDAkPD4hKt3hKt3hKPIDTt3RUPIUQTMkKDYlKuEkQtDDRQEDU3n1TE0TQUETS5IUYEoGTTslZUUTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hK2rhKtPUPIUETMEDTtHjZFkkKDYmPEAELS4TU5ckPEoGUSEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDjKTETRUAUSAAkKBolQY4BQlITQPAyTNUkdW0zZDEkKXcEVxU0UY4BQPIDQt3hKt3hKt3BTAAkKtTETRUDUS4BQl4xaQYjKAYGTAQENpMUQ3T0TOEEUQwTPlM1Y2Y0XqEDTtjDTt3hKt3hKt3hKt3hKtPUPIUETMEDTtHjZFkkKDYmPEAELS4TU5cEUIUUTBEjYic1cVM1ZAAkKIAkKt3hKt3hKt3RQtDDTRIENEQUPQUjTSEDTtHjZpQ0ct.kKBQkKtjTRqwjKDYlKE4hKt3hKt3hKt3hKt3hYRUUSTEETIckVwTjQisVTTgkdEYjKAQjYPQSPWgUdMcjKAQjct3hdA4hKt3hKt3hKtnTUv.UQAslXuk0UXoWUFE0YQcEV77RRC8Vav8lak4Fc9vyKVMEUy.Ea0cVZtMEcgQWY9.."
                                    },
                                    "fileref": {
                                        "name": "AmpModeler",
                                        "filename": "AmpModeler.maxsnap",
                                        "filepath": "D:/Documents/Max 9/Snapshots",
                                        "filepos": -1,
                                        "snapshotfileid": "d89a206b6ff1ec2ee81d2b68a8a5f9ae"
                                    }
                                }
                            ]
                        }
                    },
                    "text": "vst~ C74_VST3:/AmpModeler",
                    "varname": "vst~[1]",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "format": 6,
                    "id": "obj-9",
                    "maxclass": "flonum",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 1172.0, 227.0, 50.0, 22.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "spectroscope~",
                    "monochrome": 0,
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 371.0, 744.0, 235.0, 403.0 ],
                    "scroll": 3,
                    "sono": 1
                }
            },
            {
                "box": {
                    "id": "obj-28",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 311.0, 84.0, 66.0, 22.0 ],
                    "text": "cycle~ 100"
                }
            },
            {
                "box": {
                    "autosave": 1,
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "id": "obj-1",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 8,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "signal", "signal", "", "list", "int", "", "", "" ],
                    "patching_rect": [ 225.0, 505.0, 471.0, 204.0 ],
                    "save": [ "#N", "vst~", "loaduniqueid", 0, "D:/Dev/clap/clap_ambient/build/clap_ambient.vst3", ";" ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_invisible": 1,
                            "parameter_longname": "vst~",
                            "parameter_modmode": 0,
                            "parameter_shortname": "vst~",
                            "parameter_type": 3
                        }
                    },
                    "saved_object_attributes": {
                        "parameter_enable": 1,
                        "parameter_mappable": 0
                    },
                    "snapshot": {
                        "filetype": "C74Snapshot",
                        "version": 2,
                        "minorversion": 0,
                        "name": "snapshotlist",
                        "origin": "vst~",
                        "type": "list",
                        "subtype": "Undefined",
                        "embed": 1,
                        "snapshot": {
                            "pluginname": "clap_ambient_debug.vst3",
                            "plugindisplayname": "Clap Ambient debug (CLAP->VST3)",
                            "pluginsavedname": "",
                            "pluginsaveduniqueid": 0,
                            "version": 1,
                            "isbank": 0,
                            "isbase64": 1,
                            "sliderorder": [],
                            "slidervisibility": [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
                            "blob": "186.VMjLgDK....O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9TiMt3hKt3hKt3hKt3hKt3BVz.kKt3hKq3hKPIlVD4hKtLySt3hKt3hKt3hKt3hKt3hRP4hKtX1Jt3hKtbyPt3hK18jKtvlVFEjKt3xMCwyKIMzasA2atUlaz4COuX0TTMCTrU2Yo41TzEFck4C."
                        },
                        "snapshotlist": {
                            "current_snapshot": 0,
                            "entries": [
                                {
                                    "filetype": "C74Snapshot",
                                    "version": 2,
                                    "minorversion": 0,
                                    "name": "Clap Ambient (CLAP->VST3)",
                                    "origin": "clap_ambient_debug.vst3",
                                    "type": "VST3",
                                    "subtype": "AudioEffect",
                                    "embed": 1,
                                    "snapshot": {
                                        "pluginname": "clap_ambient_debug.vst3",
                                        "plugindisplayname": "Clap Ambient debug (CLAP->VST3)",
                                        "pluginsavedname": "",
                                        "pluginsaveduniqueid": 0,
                                        "version": 1,
                                        "isbank": 0,
                                        "isbase64": 1,
                                        "sliderorder": [],
                                        "slidervisibility": [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
                                        "blob": "186.VMjLgDK....O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9TiMt3hKt3hKt3hKt3hKt3BVz.kKt3hKq3hKPIlVD4hKtLySt3hKt3hKt3hKt3hKt3hRP4hKtX1Jt3hKtbyPt3hK18jKtvlVFEjKt3xMCwyKIMzasA2atUlaz4COuX0TTMCTrU2Yo41TzEFck4C."
                                    },
                                    "fileref": {
                                        "name": "Clap Ambient (CLAP->VST3)",
                                        "filename": "Clap Ambient (CLAP->VST3).maxsnap",
                                        "filepath": "D:/Documents/Max 9/Snapshots",
                                        "filepos": -1,
                                        "snapshotfileid": "56b535adea36a41a4157dd9e3392699b"
                                    }
                                }
                            ]
                        }
                    },
                    "text": "vst~ D:/Dev/clap/clap_ambient/build/clap_ambient.vst3",
                    "varname": "vst~",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-35",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 933.0, 233.0, 40.0, 22.0 ],
                    "text": "*~ 0.5"
                }
            },
            {
                "box": {
                    "id": "obj-34",
                    "maxclass": "button",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 1037.0, 266.0, 24.0, 24.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-32",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 1040.0, 316.0, 39.0, 22.0 ],
                    "text": "click~"
                }
            },
            {
                "box": {
                    "id": "obj-25",
                    "maxclass": "live.scope~",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 664.0, 744.0, 64.0, 351.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-20",
                    "maxclass": "newobj",
                    "numinlets": 11,
                    "numoutlets": 3,
                    "outlettype": [ "signal", "signal", "" ],
                    "patching_rect": [ 1064.0, 403.0, 318.99999999999955, 22.0 ],
                    "text": "live.adsr~"
                }
            },
            {
                "box": {
                    "decay_time": 1.5,
                    "id": "obj-19",
                    "maxclass": "live.adsrui",
                    "numinlets": 10,
                    "numoutlets": 10,
                    "outlettype": [ "", "", "", "", "", "", "", "", "", "" ],
                    "patching_rect": [ 1094.0, 285.0, 289.0, 94.0 ],
                    "release_time": 153.0
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 933.0, 274.0, 29.5, 22.0 ],
                    "text": "*~"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 4,
                    "outlettype": [ "signal", "signal", "signal", "signal" ],
                    "patching_rect": [ 933.0, 194.0, 81.0, 22.0 ],
                    "text": "svf~ 5000 0.2"
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 933.0, 132.0, 44.0, 22.0 ],
                    "text": "noise~"
                }
            },
            {
                "box": {
                    "clipheight": 33.0,
                    "data": {
                        "clips": [
                            {
                                "absolutepath": "LazyBallade.wav",
                                "filename": "LazyBallade.wav",
                                "filekind": "audiofile",
                                "id": "u119000441",
                                "selection": [ 0.0, 1.0 ],
                                "loop": 1,
                                "content_state": {
                                    "loop": 1
                                }
                            },
                            {
                                "absolutepath": "Snare 01.wav",
                                "filename": "Snare 01.wav",
                                "filekind": "audiofile",
                                "id": "u464000535",
                                "selection": [ 0.0, 1.0 ],
                                "loop": 0,
                                "content_state": {
                                    "loop": 0
                                }
                            }
                        ]
                    },
                    "id": "obj-10",
                    "maxclass": "playlist~",
                    "mode": "basic",
                    "numinlets": 1,
                    "numoutlets": 5,
                    "outlettype": [ "signal", "signal", "signal", "", "dictionary" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 478.0, 63.0, 285.0, 68.0 ],
                    "quality": "basic",
                    "saved_attribute_attributes": {
                        "candicane2": {
                            "expression": ""
                        },
                        "candicane3": {
                            "expression": ""
                        },
                        "candicane4": {
                            "expression": ""
                        },
                        "candicane5": {
                            "expression": ""
                        },
                        "candicane6": {
                            "expression": ""
                        },
                        "candicane7": {
                            "expression": ""
                        },
                        "candicane8": {
                            "expression": ""
                        }
                    }
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 305.0, 150.0, 58.0, 22.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "signal" ],
                    "patching_rect": [ 244.0, 187.0, 39.0, 22.0 ],
                    "text": "click~"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "button",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 244.0, 152.0, 24.0, 24.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-22",
                    "maxclass": "ezadc~",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patching_rect": [ 87.0, 44.0, 45.0, 45.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "outlettype": [ "signal", "signal" ],
                    "patcher": {
                        "fileversion": 1,
                        "appversion": {
                            "major": 9,
                            "minor": 1,
                            "revision": 2,
                            "architecture": "x64",
                            "modernui": 1
                        },
                        "classnamespace": "box",
                        "rect": [ 57.0, 125.0, 640.0, 480.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "obj-6",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 2,
                                    "outlettype": [ "signal", "signal" ],
                                    "patching_rect": [ 50.0, 101.66666209697723, 146.0, 22.0 ],
                                    "text": "limi~ 2 512 @threshold -3"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-39",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 1,
                                    "outlettype": [ "int" ],
                                    "patching_rect": [ 299.16666650772095, 168.33333790302277, 33.0, 22.0 ],
                                    "text": "== 0"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-37",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 49.66666650772095, 213.33333790302277, 34.0, 22.0 ],
                                    "text": "*~ 1."
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-36",
                                    "maxclass": "newobj",
                                    "numinlets": 2,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 176.66666650772095, 213.33333790302277, 34.0, 22.0 ],
                                    "text": "*~ 1."
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-32",
                                    "maxclass": "newobj",
                                    "numinlets": 3,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 176.66666650772095, 150.0, 78.0, 22.0 ],
                                    "text": "clip~ -0.9 0.9"
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-31",
                                    "maxclass": "newobj",
                                    "numinlets": 3,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 49.66666650772095, 150.0, 78.0, 22.0 ],
                                    "text": "clip~ -0.9 0.9"
                                }
                            },
                            {
                                "box": {
                                    "comment": "",
                                    "id": "obj-1",
                                    "index": 1,
                                    "maxclass": "inlet",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 50.0, 40.0, 30.0, 30.0 ]
                                }
                            },
                            {
                                "box": {
                                    "comment": "",
                                    "id": "obj-2",
                                    "index": 2,
                                    "maxclass": "inlet",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "signal" ],
                                    "patching_rect": [ 177.0, 40.0, 30.0, 30.0 ]
                                }
                            },
                            {
                                "box": {
                                    "comment": "",
                                    "id": "obj-3",
                                    "index": 3,
                                    "maxclass": "inlet",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "int" ],
                                    "patching_rect": [ 299.16666650772095, 123.33333790302277, 30.0, 30.0 ]
                                }
                            },
                            {
                                "box": {
                                    "comment": "",
                                    "id": "obj-4",
                                    "index": 1,
                                    "maxclass": "outlet",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 49.66666650772095, 270.0, 30.0, 30.0 ]
                                }
                            },
                            {
                                "box": {
                                    "comment": "",
                                    "id": "obj-5",
                                    "index": 2,
                                    "maxclass": "outlet",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 176.66666650772095, 270.0, 30.0, 30.0 ]
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "obj-6", 0 ],
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-6", 1 ],
                                    "source": [ "obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-39", 0 ],
                                    "source": [ "obj-3", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-37", 0 ],
                                    "source": [ "obj-31", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-36", 0 ],
                                    "source": [ "obj-32", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-5", 0 ],
                                    "source": [ "obj-36", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-4", 0 ],
                                    "source": [ "obj-37", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-36", 1 ],
                                    "midpoints": [ 308.66666650772095, 192.33333790302277, 201.16666650772095, 192.33333790302277 ],
                                    "order": 0,
                                    "source": [ "obj-39", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-37", 1 ],
                                    "midpoints": [ 308.66666650772095, 192.33333790302277, 74.16666650772095, 192.33333790302277 ],
                                    "order": 1,
                                    "source": [ "obj-39", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-31", 0 ],
                                    "source": [ "obj-6", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-32", 0 ],
                                    "source": [ "obj-6", 1 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 158.0, 888.0, 70.0, 22.0 ],
                    "text": "p Clip-Mute"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "toggle",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "int" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 234.0, 888.0, 60.0, 60.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-17",
                    "lastchannelcount": 0,
                    "maxclass": "live.gain~",
                    "numinlets": 2,
                    "numoutlets": 5,
                    "outlettype": [ "signal", "signal", "", "float", "list" ],
                    "parameter_enable": 1,
                    "patching_rect": [ 158.0, 918.0, 70.0, 136.0 ],
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_longname": "live.gain~[1]",
                            "parameter_mmax": 0.0,
                            "parameter_mmin": -24.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "OutLevel",
                            "parameter_type": 0,
                            "parameter_unitstyle": 4
                        }
                    },
                    "varname": "live.gain~[1]"
                }
            },
            {
                "box": {
                    "id": "obj-18",
                    "maxclass": "ezdac~",
                    "numinlets": 2,
                    "numoutlets": 0,
                    "patching_rect": [ 234.0, 994.0, 60.0, 60.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 305.0, 181.0, 377.0, 22.0 ],
                    "text": "plug D:/Dev/clap/clap_ambient/build/debug/clap_ambient_debug.vst3"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-15", 1 ],
                    "source": [ "obj-1", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "order": 2,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "order": 0,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "order": 1,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 1 ],
                    "order": 0,
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "order": 1,
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-35", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 1 ],
                    "order": 0,
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "order": 1,
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 1 ],
                    "source": [ "obj-15", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 2 ],
                    "midpoints": [ 243.5, 951.1024378538132, 231.26674485206604, 951.1024378538132, 231.26674485206604, 882.1024378538132, 218.5, 882.1024378538132 ],
                    "source": [ "obj-16", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 1 ],
                    "midpoints": [ 180.25, 1065.1024378538132, 230.62244534492493, 1065.1024378538132, 230.62244534492493, 987.1024378538132, 284.5, 987.1024378538132 ],
                    "source": [ "obj-17", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "midpoints": [ 167.5, 1065.1024378538132, 230.79023385047913, 1065.1024378538132, 230.79023385047913, 990.1024378538132, 243.5, 990.1024378538132 ],
                    "source": [ "obj-17", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 10 ],
                    "source": [ "obj-19", 9 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 9 ],
                    "source": [ "obj-19", 8 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 8 ],
                    "source": [ "obj-19", 7 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 7 ],
                    "source": [ "obj-19", 6 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 6 ],
                    "source": [ "obj-19", 5 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 5 ],
                    "source": [ "obj-19", 4 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 4 ],
                    "source": [ "obj-19", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 3 ],
                    "source": [ "obj-19", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 2 ],
                    "source": [ "obj-19", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 1 ],
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 1 ],
                    "order": 0,
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "order": 1,
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 1 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-11", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "source": [ "obj-34", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-35", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 1 ],
                    "source": [ "obj-8", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-1", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-19", 3 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-1": [ "vst~", "vst~", 0 ],
            "obj-17": [ "live.gain~[1]", "OutLevel", 0 ],
            "obj-8": [ "vst~[1]", "vst~[1]", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-16", "obj-18", "obj-17", "obj-15" ]
            }
        ],
        "toolbaradditions": [ "AudioMix", "browsegendsp", "packagemanager", "ABL Effect Modules", "RNBO Guitar Pedals", "BEAP" ],
        "toolbarexclusions": [ "browser_images", "browser_video", "browser_module" ]
    }
}