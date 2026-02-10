package com.sparrowinvest.app.ui.explore

import androidx.lifecycle.ViewModel
import com.sparrowinvest.app.data.model.Advisor
import com.sparrowinvest.app.data.repository.AdvisorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class AdvisorViewModel @Inject constructor(
    private val advisorRepository: AdvisorRepository
) : ViewModel() {

    private val _advisors = MutableStateFlow<List<Advisor>>(emptyList())
    val advisors: StateFlow<List<Advisor>> = _advisors.asStateFlow()

    private val _selectedRegion = MutableStateFlow<String?>(null)
    val selectedRegion: StateFlow<String?> = _selectedRegion.asStateFlow()

    private val _allRegions = MutableStateFlow<List<String>>(emptyList())
    val allRegions: StateFlow<List<String>> = _allRegions.asStateFlow()

    val filteredAdvisors: List<Advisor>
        get() {
            val region = _selectedRegion.value
            return if (region == null) {
                _advisors.value
            } else {
                _advisors.value.filter { it.region.equals(region, ignoreCase = true) }
            }
        }

    init {
        loadAdvisors()
    }

    private fun loadAdvisors() {
        _advisors.value = advisorRepository.getAdvisors()
        _allRegions.value = advisorRepository.getAllRegions()
    }

    fun setRegion(region: String?) {
        _selectedRegion.value = region
    }

    fun getAdvisorById(advisorId: String): Advisor? {
        return advisorRepository.getAdvisorById(advisorId)
    }
}
