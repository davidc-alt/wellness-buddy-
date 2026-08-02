#!/usr/bin/env python3
import os
import uuid

def generate_pbxproj():
    project_dir = "/Users/davidbondarescu/WellnessBuddy"
    xcodeproj_dir = os.path.join(project_dir, "WellnessBuddy.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)
    
    # Define files
    sources = [
        ("Models/ProtocolModels.swift", "ProtocolModels.swift"),
        ("Services/NotificationService.swift", "NotificationService.swift"),
        ("Services/FullscriptService.swift", "FullscriptService.swift"),
        ("Services/APIService.swift", "APIService.swift"),
        ("ViewModels/WellnessBuddyViewModel.swift", "WellnessBuddyViewModel.swift"),
        ("Components/CalmDesignComponents.swift", "CalmDesignComponents.swift"),
        ("Views/ClientLoginView.swift", "ClientLoginView.swift"),
        ("Views/PersistentReminderBannerView.swift", "PersistentReminderBannerView.swift"),
        ("Views/SupplementTrackerView.swift", "SupplementTrackerView.swift"),
        ("Views/MessagesView.swift", "MessagesView.swift"),
        ("Views/FullscriptPortalView.swift", "FullscriptPortalView.swift"),
        ("Views/ComplianceStatsView.swift", "ComplianceStatsView.swift"),
        ("Views/PractitionerDashboardView.swift", "PractitionerDashboardView.swift"),
        ("Views/ClientDashboardView.swift", "ClientDashboardView.swift"),
        ("WellnessBuddyApp.swift", "WellnessBuddyApp.swift"),
    ]
    
    def make_id(name):
        return uuid.uuid5(uuid.NAMESPACE_DNS, name).hex[:24].upper()

    file_refs = []
    build_files = []
    source_ref_ids = []
    
    for rel_path, name in sources:
        f_id = make_id("FILE_" + rel_path)
        b_id = make_id("BUILD_" + rel_path)
        file_refs.append(f'		{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{rel_path}"; sourceTree = "<group>"; }};')
        build_files.append(f'		{b_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {name} */; }};')
        source_ref_ids.append((b_id, name))

    info_plist_id = make_id("INFOPLIST")
    file_refs.append(f'		{info_plist_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};')
    
    all_file_ids_in_group = [f'		{make_id("FILE_" + r[0])} /* {r[1]} */,' for r in sources]
    all_file_ids_in_group.append(f'		{info_plist_id} /* Info.plist */,')

    sources_build_phase_id = make_id("PBXSourcesBuildPhase")
    sources_build_files = [f'		{b_id} /* {name} in Sources */,' for b_id, name in source_ref_ids]

    app_target_id = make_id("PBXNativeTarget")
    app_product_id = make_id("PBXFileReferenceApp")
    config_list_target_id = make_id("XCConfigurationListTarget")
    config_list_proj_id = make_id("XCConfigurationListProject")
    debug_target_id = make_id("XCBuildConfigurationDebugTarget")
    release_target_id = make_id("XCBuildConfigurationReleaseTarget")
    debug_proj_id = make_id("XCBuildConfigurationDebugProject")
    release_proj_id = make_id("XCBuildConfigurationReleaseProject")

    pbxproj_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{app_product_id} /* WellnessBuddy.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WellnessBuddy.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXGroup section */
		{make_id("MAIN_GROUP")} = {{
			isa = PBXGroup;
			children = (
				{make_id("APP_GROUP")} /* WellnessBuddy */,
				{app_product_id} /* WellnessBuddy.app */,
			);
			sourceTree = "<group>";
		}};
		{make_id("APP_GROUP")} = {{
			isa = PBXGroup;
			children = (
{chr(10).join(all_file_ids_in_group)}
			);
			path = WellnessBuddy;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{app_target_id} /* WellnessBuddy */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {config_list_target_id} /* Build configuration list for PBXNativeTarget "WellnessBuddy" */;
			buildPhases = (
				{sources_build_phase_id} /* Sources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WellnessBuddy;
			productName = WellnessBuddy;
			productReference = {app_product_id} /* WellnessBuddy.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{make_id("PBXProject")} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{app_target_id} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {config_list_proj_id} /* Build configuration list for PBXProject "WellnessBuddy" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {make_id("MAIN_GROUP")};
			productRefGroup = {make_id("MAIN_GROUP")};
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{app_target_id} /* WellnessBuddy */,
			);
		}};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		{sources_build_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(sources_build_files)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_proj_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{release_proj_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
		{debug_target_id} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "";
				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = WellnessBuddy/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wellnessbuddy.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{release_target_id} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CODE_SIGN_IDENTITY = "";
				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = WellnessBuddy/Info.plist;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wellnessbuddy.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{config_list_proj_id} /* Build configuration list for PBXProject "WellnessBuddy" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_proj_id} /* Debug */,
				{release_proj_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{config_list_target_id} /* Build configuration list for PBXNativeTarget "WellnessBuddy" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target_id} /* Debug */,
				{release_target_id} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {make_id("PBXProject")} /* Project object */;
}}
"""

    with open(os.path.join(xcodeproj_dir, "project.pbxproj"), "w") as f:
        f.write(pbxproj_content)

    print("Successfully generated project.pbxproj!")

if __name__ == "__main__":
    generate_pbxproj()
