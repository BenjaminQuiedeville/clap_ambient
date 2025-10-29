{
	"patcher" : 	{
		"fileversion" : 1,
		"appversion" : 		{
			"major" : 9,
			"minor" : 0,
			"revision" : 7,
			"architecture" : "x64",
			"modernui" : 1
		}
,
		"classnamespace" : "box",
		"rect" : [ 34.0, 77.0, 1852.0, 939.0 ],
		"gridsize" : [ 15.0, 15.0 ],
		"subpatcher_template" : "empty_mixer",
		"boxes" : [ 			{
				"box" : 				{
					"id" : "obj-8",
					"maxclass" : "live.scope~",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 150.0, 172.0, 184.0, 68.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-7",
					"maxclass" : "live.scope~",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"patching_rect" : [ 973.0, 407.0, 184.0, 68.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-6",
					"maxclass" : "button",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "bang" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 416.0, 75.0, 24.0, 24.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-3",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "signal" ],
					"patching_rect" : [ 420.199995756149292, 137.0, 44.0, 22.0 ],
					"text" : "noise~"
				}

			}
, 			{
				"box" : 				{
					"autosave" : 1,
					"bgmode" : 0,
					"border" : 0,
					"clickthrough" : 0,
					"id" : "obj-1",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 8,
					"offset" : [ 0.0, 0.0 ],
					"outlettype" : [ "signal", "signal", "", "list", "int", "", "", "" ],
					"patching_rect" : [ 390.0, 176.0, 445.0, 159.0 ],
					"save" : [ "#N", "vst~", "loaduniqueid", 0, "D:/Dev/clap/clap_ambient/build/clap_ambient.vst3", ";" ],
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_invisible" : 1,
							"parameter_longname" : "vst~",
							"parameter_modmode" : 0,
							"parameter_shortname" : "vst~",
							"parameter_type" : 3
						}

					}
,
					"saved_object_attributes" : 					{
						"parameter_enable" : 1,
						"parameter_mappable" : 0
					}
,
					"snapshot" : 					{
						"filetype" : "C74Snapshot",
						"version" : 2,
						"minorversion" : 0,
						"name" : "snapshotlist",
						"origin" : "vst~",
						"type" : "list",
						"subtype" : "Undefined",
						"embed" : 1,
						"snapshot" : 						{
							"pluginname" : "clap_ambient.vst3",
							"plugindisplayname" : "Clap Ambient (CLAP->VST3)",
							"pluginsavedname" : "",
							"pluginsaveduniqueid" : 0,
							"version" : 1,
							"isbank" : 0,
							"isbase64" : 1,
							"sliderorder" : [  ],
							"slidervisibility" : [ 1, 1, 1 ],
							"blob" : "127.VMjLgXG....O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9DiLt3hKls1PA4hKtbyPt3hKt3BOujzPu0Fbu4VYtQmO77hUSQ0LPwVcmklaSQWXzUlO.."
						}
,
						"snapshotlist" : 						{
							"current_snapshot" : 0,
							"entries" : [ 								{
									"filetype" : "C74Snapshot",
									"version" : 2,
									"minorversion" : 0,
									"name" : "Clap Ambient (CLAP->VST3)",
									"origin" : "clap_ambient.vst3",
									"type" : "VST3",
									"subtype" : "AudioEffect",
									"embed" : 0,
									"snapshot" : 									{
										"pluginname" : "clap_ambient.vst3",
										"plugindisplayname" : "Clap Ambient (CLAP->VST3)",
										"pluginsavedname" : "",
										"pluginsaveduniqueid" : 0,
										"version" : 1,
										"isbank" : 0,
										"isbase64" : 1,
										"sliderorder" : [  ],
										"slidervisibility" : [ 1, 1, 1 ],
										"blob" : "127.VMjLgXG....O+fWarAhckI2bo8la8HRLt.iHfTlai8FYo41Y8HRUTYTK3HxO9.BOVMEUy.Ea0cVZtMEcgQWY9vSRC8Vav8lak4Fc9DiLt3hKls1PA4hKtbyPt3hKt3BOujzPu0Fbu4VYtQmO77hUSQ0LPwVcmklaSQWXzUlO.."
									}
,
									"fileref" : 									{
										"name" : "Clap Ambient (CLAP->VST3)",
										"filename" : "Clap Ambient (CLAP->VST3).maxsnap",
										"filepath" : "D:/Documents/Max 9/Snapshots",
										"filepos" : -1,
										"snapshotfileid" : "d566cc8062821cd6d125b2f4469efd2c"
									}

								}
 ]
						}

					}
,
					"text" : "vst~ D:/Dev/clap/clap_ambient/build/clap_ambient.vst3",
					"varname" : "vst~",
					"viewvisibility" : 1
				}

			}
, 			{
				"box" : 				{
					"annotation" : "A simple stereo audio mixing module. ",
					"bgmode" : 0,
					"border" : 0,
					"clickthrough" : 0,
					"enablehscroll" : 0,
					"enablevscroll" : 0,
					"id" : "obj-29",
					"lockeddragscroll" : 0,
					"lockedsize" : 0,
					"maxclass" : "bpatcher",
					"name" : "AudioMix.maxpat",
					"numinlets" : 3,
					"numoutlets" : 3,
					"offset" : [ 0.0, 0.0 ],
					"outlettype" : [ "signal", "signal", "" ],
					"patching_rect" : [ 420.199995756149292, 434.79999977350235, 69.0, 139.0 ],
					"varname" : "AudioMix[5]",
					"viewvisibility" : 1
				}

			}
, 			{
				"box" : 				{
					"annotation" : "A simple stereo audio mixing module. ",
					"bgmode" : 0,
					"border" : 0,
					"clickthrough" : 0,
					"enablehscroll" : 0,
					"enablevscroll" : 0,
					"id" : "obj-26",
					"lockeddragscroll" : 0,
					"lockedsize" : 0,
					"maxclass" : "bpatcher",
					"name" : "AudioMix.maxpat",
					"numinlets" : 3,
					"numoutlets" : 3,
					"offset" : [ 0.0, 0.0 ],
					"outlettype" : [ "signal", "signal", "" ],
					"patching_rect" : [ 344.99999463558197, 434.79999977350235, 69.0, 139.0 ],
					"varname" : "AudioMix[2]",
					"viewvisibility" : 1
				}

			}
, 			{
				"box" : 				{
					"annotation" : "A simple stereo audio mixing module. ",
					"bgmode" : 0,
					"border" : 0,
					"clickthrough" : 0,
					"enablehscroll" : 0,
					"enablevscroll" : 0,
					"id" : "obj-25",
					"lockeddragscroll" : 0,
					"lockedsize" : 0,
					"maxclass" : "bpatcher",
					"name" : "AudioMix.maxpat",
					"numinlets" : 3,
					"numoutlets" : 3,
					"offset" : [ 0.0, 0.0 ],
					"outlettype" : [ "signal", "signal", "" ],
					"patching_rect" : [ 269.799993515014648, 434.79999977350235, 69.0, 139.0 ],
					"varname" : "AudioMix[1]",
					"viewvisibility" : 1
				}

			}
, 			{
				"box" : 				{
					"annotation" : "A simple stereo audio mixing module. ",
					"bgmode" : 0,
					"border" : 0,
					"clickthrough" : 0,
					"enablehscroll" : 0,
					"enablevscroll" : 0,
					"id" : "obj-5",
					"lockeddragscroll" : 0,
					"lockedsize" : 0,
					"maxclass" : "bpatcher",
					"name" : "AudioMix.maxpat",
					"numinlets" : 3,
					"numoutlets" : 3,
					"offset" : [ 0.0, 0.0 ],
					"outlettype" : [ "signal", "signal", "" ],
					"patching_rect" : [ 194.599992394447327, 434.79999977350235, 69.0, 139.0 ],
					"varname" : "AudioMix",
					"viewvisibility" : 1
				}

			}
, 			{
				"box" : 				{
					"automatic" : 1,
					"id" : "obj-23",
					"maxclass" : "scope~",
					"numinlets" : 2,
					"numoutlets" : 0,
					"patching_rect" : [ 705.0, 450.0, 130.0, 130.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-22",
					"maxclass" : "ezadc~",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "signal", "signal" ],
					"patching_rect" : [ 150.0, 45.0, 45.0, 45.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-15",
					"maxclass" : "newobj",
					"numinlets" : 3,
					"numoutlets" : 2,
					"outlettype" : [ "signal", "signal" ],
					"patcher" : 					{
						"fileversion" : 1,
						"appversion" : 						{
							"major" : 9,
							"minor" : 0,
							"revision" : 7,
							"architecture" : "x64",
							"modernui" : 1
						}
,
						"classnamespace" : "box",
						"rect" : [ 57.0, 125.0, 640.0, 480.0 ],
						"gridsize" : [ 15.0, 15.0 ],
						"boxes" : [ 							{
								"box" : 								{
									"id" : "obj-6",
									"maxclass" : "newobj",
									"numinlets" : 2,
									"numoutlets" : 2,
									"outlettype" : [ "signal", "signal" ],
									"patching_rect" : [ 50.0, 101.666662096977234, 146.0, 22.0 ],
									"text" : "limi~ 2 512 @threshold -3"
								}

							}
, 							{
								"box" : 								{
									"id" : "obj-39",
									"maxclass" : "newobj",
									"numinlets" : 2,
									"numoutlets" : 1,
									"outlettype" : [ "int" ],
									"patching_rect" : [ 299.166666507720947, 168.333337903022766, 33.0, 22.0 ],
									"text" : "== 0"
								}

							}
, 							{
								"box" : 								{
									"id" : "obj-37",
									"maxclass" : "newobj",
									"numinlets" : 2,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 49.666666507720947, 213.333337903022766, 34.0, 22.0 ],
									"text" : "*~ 1."
								}

							}
, 							{
								"box" : 								{
									"id" : "obj-36",
									"maxclass" : "newobj",
									"numinlets" : 2,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 176.666666507720947, 213.333337903022766, 34.0, 22.0 ],
									"text" : "*~ 1."
								}

							}
, 							{
								"box" : 								{
									"id" : "obj-32",
									"maxclass" : "newobj",
									"numinlets" : 3,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 176.666666507720947, 150.0, 78.0, 22.0 ],
									"text" : "clip~ -0.9 0.9"
								}

							}
, 							{
								"box" : 								{
									"id" : "obj-31",
									"maxclass" : "newobj",
									"numinlets" : 3,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 49.666666507720947, 150.0, 78.0, 22.0 ],
									"text" : "clip~ -0.9 0.9"
								}

							}
, 							{
								"box" : 								{
									"comment" : "",
									"id" : "obj-1",
									"index" : 1,
									"maxclass" : "inlet",
									"numinlets" : 0,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 50.0, 40.0, 30.0, 30.0 ]
								}

							}
, 							{
								"box" : 								{
									"comment" : "",
									"id" : "obj-2",
									"index" : 2,
									"maxclass" : "inlet",
									"numinlets" : 0,
									"numoutlets" : 1,
									"outlettype" : [ "signal" ],
									"patching_rect" : [ 177.0, 40.0, 30.0, 30.0 ]
								}

							}
, 							{
								"box" : 								{
									"comment" : "",
									"id" : "obj-3",
									"index" : 3,
									"maxclass" : "inlet",
									"numinlets" : 0,
									"numoutlets" : 1,
									"outlettype" : [ "int" ],
									"patching_rect" : [ 299.166666507720947, 123.333337903022766, 30.0, 30.0 ]
								}

							}
, 							{
								"box" : 								{
									"comment" : "",
									"id" : "obj-4",
									"index" : 1,
									"maxclass" : "outlet",
									"numinlets" : 1,
									"numoutlets" : 0,
									"patching_rect" : [ 49.666666507720947, 270.0, 30.0, 30.0 ]
								}

							}
, 							{
								"box" : 								{
									"comment" : "",
									"id" : "obj-5",
									"index" : 2,
									"maxclass" : "outlet",
									"numinlets" : 1,
									"numoutlets" : 0,
									"patching_rect" : [ 176.666666507720947, 270.0, 30.0, 30.0 ]
								}

							}
 ],
						"lines" : [ 							{
								"patchline" : 								{
									"destination" : [ "obj-6", 0 ],
									"source" : [ "obj-1", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-6", 1 ],
									"source" : [ "obj-2", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-39", 0 ],
									"source" : [ "obj-3", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-37", 0 ],
									"source" : [ "obj-31", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-36", 0 ],
									"source" : [ "obj-32", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-5", 0 ],
									"source" : [ "obj-36", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-4", 0 ],
									"source" : [ "obj-37", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-36", 1 ],
									"midpoints" : [ 308.666666507720947, 192.333337903022766, 201.166666507720947, 192.333337903022766 ],
									"order" : 0,
									"source" : [ "obj-39", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-37", 1 ],
									"midpoints" : [ 308.666666507720947, 192.333337903022766, 74.166666507720947, 192.333337903022766 ],
									"order" : 1,
									"source" : [ "obj-39", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-31", 0 ],
									"source" : [ "obj-6", 0 ]
								}

							}
, 							{
								"patchline" : 								{
									"destination" : [ "obj-32", 0 ],
									"source" : [ "obj-6", 1 ]
								}

							}
 ]
					}
,
					"patching_rect" : [ 523.399997293949127, 450.0, 70.0, 22.0 ],
					"text" : "p Clip-Mute"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-16",
					"maxclass" : "toggle",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "int" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 599.399998426437378, 450.0, 60.0, 60.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-17",
					"lastchannelcount" : 0,
					"maxclass" : "live.gain~",
					"numinlets" : 2,
					"numoutlets" : 5,
					"outlettype" : [ "signal", "signal", "", "float", "list" ],
					"parameter_enable" : 1,
					"patching_rect" : [ 523.399997293949127, 479.600000441074371, 70.0, 136.0 ],
					"saved_attribute_attributes" : 					{
						"valueof" : 						{
							"parameter_initial" : [ 0.0 ],
							"parameter_initial_enable" : 1,
							"parameter_longname" : "live.gain~[1]",
							"parameter_mmax" : 0.0,
							"parameter_mmin" : -24.0,
							"parameter_modmode" : 3,
							"parameter_shortname" : "OutLevel",
							"parameter_type" : 0,
							"parameter_unitstyle" : 4
						}

					}
,
					"varname" : "live.gain~[1]"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-18",
					"maxclass" : "ezdac~",
					"numinlets" : 2,
					"numoutlets" : 0,
					"patching_rect" : [ 599.399998426437378, 556.400001585483551, 60.0, 60.0 ]
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"destination" : [ "obj-23", 0 ],
					"order" : 1,
					"source" : [ "obj-1", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-7", 1 ],
					"source" : [ "obj-1", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-7", 0 ],
					"order" : 0,
					"source" : [ "obj-1", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-17", 1 ],
					"source" : [ "obj-15", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-17", 0 ],
					"source" : [ "obj-15", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 2 ],
					"midpoints" : [ 608.899998426437378, 513.102437853813171, 596.666742146015167, 513.102437853813171, 596.666742146015167, 444.102437853813171, 583.899997293949127, 444.102437853813171 ],
					"source" : [ "obj-16", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-18", 1 ],
					"midpoints" : [ 545.649997293949127, 627.102437853813171, 596.022442638874054, 627.102437853813171, 596.022442638874054, 549.102437853813171, 649.899998426437378, 549.102437853813171 ],
					"source" : [ "obj-17", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-18", 0 ],
					"midpoints" : [ 532.899997293949127, 627.102437853813171, 596.190231144428253, 627.102437853813171, 596.190231144428253, 552.102437853813171, 608.899998426437378, 552.102437853813171 ],
					"source" : [ "obj-17", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 1 ],
					"midpoints" : [ 304.299993515014648, 585.0, 510.0, 585.0, 510.0, 435.0, 558.399997293949127, 435.0 ],
					"source" : [ "obj-25", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 0 ],
					"midpoints" : [ 279.299993515014648, 585.0, 510.0, 585.0, 510.0, 447.0, 532.899997293949127, 447.0 ],
					"source" : [ "obj-25", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 1 ],
					"midpoints" : [ 379.49999463558197, 585.0, 510.0, 585.0, 510.0, 435.0, 558.399997293949127, 435.0 ],
					"source" : [ "obj-26", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 0 ],
					"midpoints" : [ 354.49999463558197, 585.0, 510.0, 585.0, 510.0, 447.0, 532.899997293949127, 447.0 ],
					"source" : [ "obj-26", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 1 ],
					"midpoints" : [ 454.699995756149292, 585.0, 510.0, 585.0, 510.0, 435.0, 558.399997293949127, 435.0 ],
					"source" : [ "obj-29", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 0 ],
					"midpoints" : [ 429.699995756149292, 585.0, 510.0, 585.0, 510.0, 447.0, 532.899997293949127, 447.0 ],
					"source" : [ "obj-29", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-1", 0 ],
					"order" : 0,
					"source" : [ "obj-3", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-8", 0 ],
					"order" : 1,
					"source" : [ "obj-3", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 1 ],
					"midpoints" : [ 229.099992394447327, 585.0, 510.0, 585.0, 510.0, 435.0, 558.399997293949127, 435.0 ],
					"source" : [ "obj-5", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 0 ],
					"midpoints" : [ 204.099992394447327, 585.0, 510.0, 585.0, 510.0, 447.0, 532.899997293949127, 447.0 ],
					"source" : [ "obj-5", 0 ]
				}

			}
 ],
		"parameters" : 		{
			"obj-1" : [ "vst~", "vst~", 0 ],
			"obj-17" : [ "live.gain~[1]", "OutLevel", 0 ],
			"obj-25::obj-113" : [ "pan[1]", "Pan", 0 ],
			"obj-25::obj-114" : [ "solo[1]", "Solo", 0 ],
			"obj-25::obj-115" : [ "active[2]", "Active", 0 ],
			"obj-25::obj-116" : [ "gain[2]", "Gain", 0 ],
			"obj-25::obj-30" : [ "qlist[1]", "Qlist", 0 ],
			"obj-25::obj-4" : [ "setname[1]", "Setname", 0 ],
			"obj-26::obj-113" : [ "pan[2]", "Pan", 0 ],
			"obj-26::obj-114" : [ "solo[2]", "Solo", 0 ],
			"obj-26::obj-115" : [ "active[3]", "Active", 0 ],
			"obj-26::obj-116" : [ "gain[3]", "Gain", 0 ],
			"obj-26::obj-30" : [ "qlist[2]", "Qlist", 0 ],
			"obj-26::obj-4" : [ "setname[2]", "Setname", 0 ],
			"obj-29::obj-113" : [ "pan[3]", "Pan", 0 ],
			"obj-29::obj-114" : [ "solo[3]", "Solo", 0 ],
			"obj-29::obj-115" : [ "active[4]", "Active", 0 ],
			"obj-29::obj-116" : [ "gain[4]", "Gain", 0 ],
			"obj-29::obj-30" : [ "qlist[3]", "Qlist", 0 ],
			"obj-29::obj-4" : [ "setname[3]", "Setname", 0 ],
			"obj-5::obj-113" : [ "pan", "Pan", 0 ],
			"obj-5::obj-114" : [ "solo", "Solo", 0 ],
			"obj-5::obj-115" : [ "active", "Active", 0 ],
			"obj-5::obj-116" : [ "gain", "Gain", 0 ],
			"obj-5::obj-30" : [ "qlist", "Qlist", 0 ],
			"obj-5::obj-4" : [ "setname", "Setname", 0 ],
			"parameterbanks" : 			{
				"0" : 				{
					"index" : 0,
					"name" : "",
					"parameters" : [ "-", "-", "-", "-", "-", "-", "-", "-" ]
				}

			}
,
			"parameter_overrides" : 			{
				"obj-25::obj-113" : 				{
					"parameter_longname" : "pan[1]"
				}
,
				"obj-25::obj-114" : 				{
					"parameter_longname" : "solo[1]"
				}
,
				"obj-25::obj-115" : 				{
					"parameter_longname" : "active[2]"
				}
,
				"obj-25::obj-116" : 				{
					"parameter_longname" : "gain[2]"
				}
,
				"obj-25::obj-30" : 				{
					"parameter_longname" : "qlist[1]"
				}
,
				"obj-26::obj-113" : 				{
					"parameter_longname" : "pan[2]"
				}
,
				"obj-26::obj-114" : 				{
					"parameter_longname" : "solo[2]"
				}
,
				"obj-26::obj-115" : 				{
					"parameter_longname" : "active[3]"
				}
,
				"obj-26::obj-116" : 				{
					"parameter_longname" : "gain[3]"
				}
,
				"obj-26::obj-30" : 				{
					"parameter_longname" : "qlist[2]"
				}
,
				"obj-29::obj-113" : 				{
					"parameter_longname" : "pan[3]"
				}
,
				"obj-29::obj-114" : 				{
					"parameter_longname" : "solo[3]"
				}
,
				"obj-29::obj-115" : 				{
					"parameter_longname" : "active[4]"
				}
,
				"obj-29::obj-116" : 				{
					"parameter_longname" : "gain[4]"
				}
,
				"obj-29::obj-30" : 				{
					"parameter_longname" : "qlist[3]"
				}

			}
,
			"inherited_shortname" : 1
		}
,
		"dependency_cache" : [ 			{
				"name" : "AudioMix.maxpat",
				"bootpath" : "D:/Documents/Max 9/Packages/AudioMix/patchers",
				"patcherrelativepath" : "../../../Documents/Max 9/Packages/AudioMix/patchers",
				"type" : "JSON",
				"implicit" : 1
			}
 ],
		"autosave" : 0,
		"boxgroups" : [ 			{
				"boxes" : [ "obj-16", "obj-18", "obj-17", "obj-15" ]
			}
 ]
	}

}
