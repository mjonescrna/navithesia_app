import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navithesia_beta/models/clinical_site_model.dart';
import 'package:navithesia_beta/constants/app_constants.dart';

class ClinicalSiteProvider with ChangeNotifier {
  List<ClinicalSite> _sites = [];
  ClinicalSite? _activeSite;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Getters
  List<ClinicalSite> get sites => _sites;
  ClinicalSite? get activeSite => _activeSite;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasActiveSite => _activeSite != null;

  // Constructor
  ClinicalSiteProvider() {
    loadSites();
  }

  // Load sites from storage
  Future<void> loadSites() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sitesJson = prefs.getString(AppConstants.clinicalSitesKey);

      if (sitesJson != null) {
        final List<dynamic> decodedSites = json.decode(sitesJson);
        _sites =
            decodedSites
                .map(
                  (siteMap) =>
                      ClinicalSite.fromMap(Map<String, dynamic>.from(siteMap)),
                )
                .toList();

        // Find active site
        _activeSite = null;

        // First try to find an active site with valid end date
        final activeValidSites =
            _sites
                .where(
                  (site) =>
                      site.isActive && site.endDate.isAfter(DateTime.now()),
                )
                .toList();

        if (activeValidSites.isNotEmpty) {
          _activeSite = activeValidSites.first;
        } else {
          // If not found, just look for any active site
          final activeSites = _sites.where((site) => site.isActive).toList();
          if (activeSites.isNotEmpty) {
            _activeSite = activeSites.first;
          }
        }
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load clinical sites: $e');
    }
  }

  // Save sites to storage
  Future<void> _saveSites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sitesJson = json.encode(
        _sites.map((site) => site.toMap()).toList(),
      );
      await prefs.setString(AppConstants.clinicalSitesKey, sitesJson);
    } catch (e) {
      _setError('Failed to save clinical sites: $e');
    }
  }

  // Add a new clinical site
  Future<void> addSite(ClinicalSite site) async {
    _setLoading(true);
    try {
      // If this is set as active, deactivate all other sites
      if (site.isActive) {
        _deactivateAllSites();
      }

      _sites.add(site);

      // If active, set as the active site
      if (site.isActive) {
        _activeSite = site;
      }

      await _saveSites();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add clinical site: $e');
    }
  }

  // Update an existing clinical site
  Future<void> updateSite(ClinicalSite updatedSite) async {
    _setLoading(true);
    try {
      final index = _sites.indexWhere((site) => site.id == updatedSite.id);
      if (index >= 0) {
        // If this is being activated, deactivate all other sites
        if (updatedSite.isActive && !_sites[index].isActive) {
          _deactivateAllSites();
        }

        _sites[index] = updatedSite;

        // Update active site reference if needed
        if (updatedSite.isActive) {
          _activeSite = updatedSite;
        } else if (_activeSite?.id == updatedSite.id) {
          _activeSite = null;
        }

        await _saveSites();
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Clinical site not found');
      }
    } catch (e) {
      _setError('Failed to update clinical site: $e');
    }
  }

  // Delete a clinical site
  Future<void> deleteSite(String siteId) async {
    _setLoading(true);
    try {
      final index = _sites.indexWhere((site) => site.id == siteId);
      if (index >= 0) {
        // If deleting the active site, clear active site reference
        if (_activeSite?.id == siteId) {
          _activeSite = null;
        }

        _sites.removeAt(index);
        await _saveSites();
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Clinical site not found');
      }
    } catch (e) {
      _setError('Failed to delete clinical site: $e');
    }
  }

  // Set a clinical site as active
  Future<void> activateSite(String siteId) async {
    _setLoading(true);
    try {
      // Deactivate all sites first
      _deactivateAllSites();

      // Activate the selected site
      final index = _sites.indexWhere((site) => site.id == siteId);
      if (index >= 0) {
        final updatedSite = _sites[index].copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );

        _sites[index] = updatedSite;
        _activeSite = updatedSite;

        await _saveSites();
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Clinical site not found');
      }
    } catch (e) {
      _setError('Failed to activate clinical site: $e');
    }
  }

  // Deactivate the current active site
  Future<void> deactivateCurrentSite() async {
    if (_activeSite == null) return;

    _setLoading(true);
    try {
      final index = _sites.indexWhere((site) => site.id == _activeSite!.id);
      if (index >= 0) {
        final updatedSite = _sites[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );

        _sites[index] = updatedSite;
        _activeSite = null;

        await _saveSites();
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to deactivate clinical site: $e');
    }
  }

  // Extend the duration of the current active site
  Future<void> extendCurrentSite(int additionalWeeks) async {
    if (_activeSite == null) {
      _setError('No active clinical site to extend');
      return;
    }

    _setLoading(true);
    try {
      final index = _sites.indexWhere((site) => site.id == _activeSite!.id);
      if (index >= 0) {
        final newDuration = _sites[index].durationWeeks + additionalWeeks;
        final updatedSite = _sites[index].copyWith(
          durationWeeks: newDuration,
          updatedAt: DateTime.now(),
        );

        _sites[index] = updatedSite;
        _activeSite = updatedSite;

        await _saveSites();
        _setLoading(false);
        notifyListeners();
      } else {
        throw Exception('Active clinical site not found in sites list');
      }
    } catch (e) {
      _setError('Failed to extend clinical site duration: $e');
    }
  }

  // Check if a site's rotation period has ended
  bool isSiteRotationExpired(ClinicalSite site) {
    final now = DateTime.now();
    final endDate = site.startDate.add(Duration(days: site.durationWeeks * 7));
    return now.isAfter(endDate);
  }

  // Check if the user needs to add a new clinical site
  bool needsNewClinicalSite() {
    // If there's no active site, we need a new one
    if (_activeSite == null) return true;

    // If the active site's rotation has expired, we need a new one
    return isSiteRotationExpired(_activeSite!);
  }

  // Get sites within date range
  List<ClinicalSite> getSitesInRange(DateTime startDate, DateTime endDate) {
    return _sites.where((site) {
      return (site.startDate.isAfter(startDate) ||
              site.startDate.isAtSameMomentAs(startDate)) &&
          (site.endDate.isBefore(endDate) ||
              site.endDate.isAtSameMomentAs(endDate));
    }).toList();
  }

  // Get all historical sites (past rotations)
  List<ClinicalSite> getHistoricalSites() {
    final now = DateTime.now();
    return _sites
        .where((site) => !site.isActive || site.endDate.isBefore(now))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate)); // Sort newest first
  }

  // Check if any sites need renewal soon
  bool get hasSitesNeedingRenewal {
    return _sites.any((site) => site.isActive && site.isEnding);
  }

  // Get sites needing renewal
  List<ClinicalSite> get sitesNeedingRenewal {
    return _sites.where((site) => site.isActive && site.isEnding).toList();
  }

  // Get a clinical site by ID
  ClinicalSite? getSiteById(String siteId) {
    try {
      return _sites.firstWhere((site) => site.id == siteId);
    } catch (e) {
      // Return null if site not found
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _hasError = true;
    _errorMessage = message;
    debugPrint('ClinicalSiteProvider Error: $message');
    notifyListeners();
  }

  void _deactivateAllSites() {
    for (int i = 0; i < _sites.length; i++) {
      if (_sites[i].isActive) {
        _sites[i] = _sites[i].copyWith(isActive: false);
      }
    }
  }
}
