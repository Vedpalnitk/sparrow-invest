package com.sparrowinvest.app.data.repository

import com.sparrowinvest.app.data.model.Advisor
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AdvisorRepository @Inject constructor() {

    private val advisors = listOf(
        Advisor(
            id = "adv-001",
            name = "Priya Sharma",
            region = "Mumbai",
            phone = "+91 98765 43210",
            email = "priya.sharma@sparrowinvest.com",
            specializations = listOf("RETIREMENT", "TAX_PLANNING", "HNI"),
            experienceYears = 15,
            rating = 4.9,
            reviewCount = 142,
            languages = listOf("English", "Hindi", "Marathi"),
            isAvailable = true
        ),
        Advisor(
            id = "adv-002",
            name = "Arun Mehta",
            region = "Delhi",
            phone = "+91 98765 43211",
            email = "arun.mehta@sparrowinvest.com",
            specializations = listOf("MUTUAL_FUNDS", "INSURANCE"),
            experienceYears = 12,
            rating = 4.7,
            reviewCount = 98,
            languages = listOf("English", "Hindi", "Punjabi"),
            isAvailable = true
        ),
        Advisor(
            id = "adv-003",
            name = "Kavitha Nair",
            region = "Bangalore",
            phone = "+91 98765 43212",
            email = "kavitha.nair@sparrowinvest.com",
            specializations = listOf("EQUITY", "ESTATE_PLANNING"),
            experienceYears = 10,
            rating = 4.8,
            reviewCount = 76,
            languages = listOf("English", "Kannada", "Malayalam"),
            isAvailable = true
        ),
        Advisor(
            id = "adv-004",
            name = "Ravi Kumar",
            region = "Chennai",
            phone = "+91 98765 43213",
            email = "ravi.kumar@sparrowinvest.com",
            specializations = listOf("NRI", "TAX_PLANNING"),
            experienceYears = 8,
            rating = 4.5,
            reviewCount = 54,
            languages = listOf("English", "Tamil", "Telugu"),
            isAvailable = false
        ),
        Advisor(
            id = "adv-005",
            name = "Sneha Gupta",
            region = "Mumbai",
            phone = "+91 98765 43214",
            email = "sneha.gupta@sparrowinvest.com",
            specializations = listOf("MUTUAL_FUNDS", "RETIREMENT"),
            experienceYears = 6,
            rating = 4.6,
            reviewCount = 38,
            languages = listOf("English", "Hindi", "Gujarati"),
            isAvailable = true
        )
    )

    fun getAdvisors(): List<Advisor> = advisors

    fun getAdvisorById(id: String): Advisor? = advisors.find { it.id == id }

    fun getAdvisorsByRegion(region: String): List<Advisor> =
        advisors.filter { it.region.equals(region, ignoreCase = true) }

    fun getAllRegions(): List<String> = advisors.map { it.region }.distinct().sorted()
}
